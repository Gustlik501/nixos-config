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
   - **Server (Frodo):** See [hosts/frodo/README.md](hosts/frodo/README.md) for special instructions on its independent sub-flake.

   *Note: This command now automatically applies both system and user (Home Manager) configurations.*

## Hosts
- `desktop`: Main workstation (Nvidia, libvirt).
- `laptop`: Portable machine (Intel).
- `frodo`: Headless home server (ZFS, Sub-flake). See its dedicated [README](hosts/frodo/README.md).
- `vm`: Virtual machine testing environment.

## Credits

[Rofi Config](https://github.com/kianblakley/niri-land)
