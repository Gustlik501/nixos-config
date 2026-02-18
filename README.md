# nixos-config

Flake-based NixOS configuration for my machines.

## Getting started

1. **Install Nix/NixOS** with the `nix-command` and `flakes` features enabled. On NixOS you can add the following to `/etc/nix/nix.conf`:
   
   ```
   experimental-features = nix-command flakes
   ```

2. **Clone this repository**:
   
   ```
   git clone <REPO_URL> ~/nixos-config
   cd ~/nixos-config
   ```

3. **Apply a host configuration**.
   
   - **Workstations:** Replace `laptop` with the desired host (`laptop` or `desktop`):
     ```
     sudo nixos-rebuild switch --flake .#laptop
     ```
   - **Server (Frodo):** See [hosts/frodo/README.md](hosts/frodo/README.md) for server-specific instructions.

   *Note: This command now automatically applies both system and user (Home Manager) configurations.*

## Helper commands
Run these from the repo root:
- Update PC inputs: `nix run .#update-pc`
- Update Frodo inputs: `nix run .#update-frodo`
- Rebuild current host: `nix run .#rebuild-pc`
- Rebuild Frodo via SSH: `nix run .#rebuild-frodo`

## Secrets (sops-nix)
- `sops-nix` is wired into all hosts through `flake.nix`.
- Secret files live under `secrets/`.
- Bootstrap and key-management notes are in `secrets/README.md`.
- Per-host SSH user private keys are managed by `modules/security/ssh-user-key-sops.nix`.
- Public SSH keys are stored in `ssh/public-keys/` (not encrypted by design).

## Hosts
- `desktop`: Main workstation (Nvidia, libvirt).
- `laptop`: Portable machine (Intel).
- `frodo`: Headless home server (ZFS). See its dedicated [README](hosts/frodo/README.md).
- `vm`: Virtual machine testing environment.

## Credits

[Rofi Config](https://github.com/kianblakley/niri-land)
