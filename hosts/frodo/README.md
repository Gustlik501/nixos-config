# Frodo: Home Server (HPE ProLiant ML30 Gen9)

This host is configured as a headless home server using ZFS for storage and NixOS for reproducibility. It uses an independent sub-flake located in `hosts/frodo/` to decouple its updates from the desktop/laptop.

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

## Initial Setup / Disaster Recovery

### 1. BIOS Configuration
- Ensure Storage Controller is in **HBA Mode** (not RAID mode).
- Disable **Secure Boot**.

### 2. Installation from Live USB
1. Boot NixOS Minimal ISO.
2. Set a temporary password: `sudo passwd nixos`.
3. Get the IP: `ip a`.
4. From your **Desktop**, copy the config:
   ```bash
   scp -r ~/nixos-config nixos@<FRODO_IP>:~
   ```

### 3. Partitioning and Formatting (Disko)
**WARNING:** This wipes all drives defined in `disk-config.nix`.
```bash
cd ~/nixos-config/hosts/frodo
sudo nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./disk-config.nix
```

### 4. System Install
```bash
sudo nixos-install --flake .#frodo
reboot
```

## Maintenance
To update Frodo, SSH into the server and run:
```bash
cd ~/nixos-config/hosts/frodo
sudo nixos-rebuild switch --flake .
```

To update the lock file (independently of the rest of the repo):
```bash
nix flake update
```

## Troubleshooting
- **Mount Failures:** If the system boots to emergency mode because ZFS is slow, the `nofail` option in `default.nix` allows the system to continue booting. Use `Ctrl+D` to skip if prompted.
- **Host ID:** If ZFS fails to import, ensure `networking.hostId` matches the ID generated during the first install.
- **SSH Fingerprint:** If you reinstall, run `ssh-keygen -R <FRODO_IP>` on your desktop to clear the old fingerprint.
