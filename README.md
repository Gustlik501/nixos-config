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

3. **Apply a host configuration**. Replace `laptop` with the desired host (`laptop` or `desktop`):
   
   - For a fresh install:
     
     ```
     sudo nixos-install --flake .#laptop
     ```
   - For an already installed system:
     
     ```
     sudo nixos-rebuild switch --flake .#laptop
     ```

   *Note: This command now automatically applies both system and user (Home Manager) configurations.*

## Credits

[Rofi Config](https://github.com/kianblakley/niri-land)
