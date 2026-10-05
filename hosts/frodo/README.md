# Frodo: Home Server (HPE ProLiant ML30 Gen9)

This host is configured as a headless home server using ZFS for storage and NixOS for reproducibility. It lives in the main flake and uses the same `nixpkgs` pin as the other hosts.

## Hardware Specs
- **CPU:** Intel Xeon (Gen9)
- **OS Drive:** 240GB Kingston SSD (`/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B778337F56F`)
- **Data (Mirror):** 2x 1TB HDD (`dpool`)
- **Media (Stripe):** 2x 4TB HDD (`mpool`)
- **GPU:** Nvidia GTX 1050 Ti

## Storage Layout (ZFS)
- `/` (Root): ext4 on SSD
- `/boot`: vfat (ESP) on SSD
- `/data`: ZFS Mirror (`dpool`) - Critical data, backups.
- `/media`: ZFS Stripe (`mpool`) - Media, torrents, non-critical storage.

NixOS `fileSystems`/systemd mount units own both ZFS mounts. The separate
`zfs-mount.service` (`zfs mount -a`) is disabled to avoid racing those units.
Pool import, scrub, trim and event monitoring remain enabled. If adding native
ZFS filesystem datasets in the future, also declare their mounts in NixOS or
revisit this single-mount-manager policy; do not just enable both mechanisms.

## Initial Setup / Disaster Recovery

### 1. BIOS Configuration
- Ensure Storage Controller is in **HBA Mode** (not RAID mode).
- Disable **Secure Boot**.

### 2. Installation from Live USB
1. Boot NixOS Minimal ISO.
2. Set a temporary password: `sudo passwd nixos`.
3. Get the IP: `ip a`.
4. From your **Desktop**, copy this repository to the installer:
   ```bash
   scp -r /path/to/clone nixos@<FRODO_IP>:~/config
   ```

### 3. Partitioning and Formatting (Disko)
**WARNING:** This wipes all drives defined in `disk-config.nix`.
```bash
cd ~/config
sudo nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./hosts/frodo/disk-config.nix
```

### 4. System Install
```bash
cd ~/config
sudo nixos-install --flake .#frodo
reboot
```

## Maintenance
To update Frodo, SSH into the server and run:
```bash
cd /path/to/clone
sudo nixos-rebuild switch --flake .#frodo
```

From the desktop, `nix run .#rebuild-frodo` (switch) and
`nix run .#rebuild-frodo-boot` (next boot) evaluate this checkout locally, transfer
source/build recipes, and **build on Frodo** using its approved binary caches.
Both `--build-host` and `--target-host` point to the same host. This avoids
importing unsigned desktop-built outputs as an untrusted SSH user. `--sudo`
authorizes activation only; it does not elevate Nix's closure transfer.
Do not restore ordinary-user Nix trust or disable signature checks to work
around deployment errors. `FRODO_HOST` overrides both hosts together.

To update all flake inputs:
```bash
nix run .#update
```

## Docker administration

Profilarr is the only Docker container declared here. Its root-owned systemd
unit starts it automatically; `gustl` deliberately is **not** in the `docker`
group, because that group grants root-equivalent control of the host. Use
`sudo docker ps` / `sudo docker logs profilarr` for manual administration.
This does not convert Docker to rootless mode or change Profilarr's data.

After deploying the group change, existing sessions/processes can retain their
old supplementary groups. Log out of all sessions and reconnect; a reboot is
the simplest way to ensure no old user processes retain Docker access. Verify
`id` no longer lists `docker` in a fresh SSH session.

## Dashboard coverage

Glance keeps its existing web-application checks and adds:

- **System services:** all configured application services, plus PostgreSQL,
  WireGuard, Hermes, SSH, Caddy, Docker and Glance. Stopped/missing services stay
  visible rather than silently disappearing.
- **System infrastructure:** every other active/transitional/failed system
  service, discovered automatically (networking, Nix daemon, NVIDIA, ZFS, etc.).
- **Scheduled maintenance timers:** active/failed system timers, including
  garbage collection, storage maintenance and log rotation.

`glance-status.service` runs every 30 seconds as an unprivileged dynamic user.
It reads systemd state and atomically writes a sanitized JSON snapshot under
`/run/glance-status`. Because systemd protects preserved DynamicUser directories
behind `/run/private`, Glance gets a **read-only bind mount** at
`/run/glance-status-assets` inside its own mount namespace. It serves that view
as assets and fetches the snapshot over loopback; no new ports, Docker socket
access, credentials, sudo rules or service-control endpoints are added. Dashboard viewers can see service
names and states, including through `/assets/status.json`; this is not private
metadata and should follow the same access policy as the dashboard itself.

These are **systemd states, not end-to-end health checks**. In particular,
WireGuard and Profilarr's Compose setup legitimately show `active / exited`;
Profilarr's existing HTTP check is still needed to check the application.
Inactive scheduled jobs are not treated as broken daemons. Per-user services
and arbitrary manually launched processes/containers are not inventoried.
Snapshot failures or data older than two minutes show an unavailable/stale
warning. Glance caches these widgets for 30 seconds; refresh the page to see
new results (the collector runs independently of the browser).

Validate changes before deployment:

```sh
python3 -B -m unittest discover -s tests -p 'test_glance_status.py' -v
nix eval --offline --impure --json --file tests/nix-security.nix
nix flake check "path:$PWD" --no-build --no-write-lock-file
# Boots an isolated VM to test real DynamicUser permissions and dashboard rendering:
nix build --impure --no-link --file tests/glance-status-vm.nix
```

Add new source files to Git before using the Git-backed `.#rebuild-frodo` helper
(in particular `modules/services/glance-status.py`); otherwise Nix excludes them
from the flake source. After deployment, check `systemctl status glance-status.timer`
and `curl http://127.0.0.1:8080/assets/status.json` on Frodo.

## Troubleshooting
- **NVIDIA driver/library mismatch after a switch:** Updating userspace does not
  replace the NVIDIA module already loaded in the running kernel. If
  `nvidia-smi` reports a driver/library version mismatch, schedule a reboot into
  the new generation. Prefer `nix run .#rebuild-frodo-boot` followed by a planned
  reboot for driver/kernel changes; do not unload a GPU driver while applications
  may be using it. A failed `nvidia-persistenced` unit can make `switch` exit with
  status 4 even though the new configuration was activated.
- **Mount Failures:** `nofail` allows boot to continue without the data/media
  mounts; it does not make missing storage safe for dependent applications.
  Check `findmnt -t zfs`, `zpool status -x`, and the mount-unit journal before
  starting stateful services. A `mountpoint or dataset is busy` error from
  `zfs-mount.service` alongside successful explicit mounts can indicate competing
  mount managers. Do not force-unmount live pools or delete underlying mountpoint
  contents just to clear this warning.
- **Host ID:** If ZFS fails to import, ensure `networking.hostId` matches the ID generated during the first install.
- **SSH Fingerprint:** If you reinstall, run `ssh-keygen -R <FRODO_IP>` on your desktop to clear the old fingerprint.
