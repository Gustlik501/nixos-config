# Project Context: NixOS Configuration

## Project Overview
This repository contains the declarative system configuration for a NixOS-based setup, managed using **Nix Flakes**. It defines configurations for multiple hosts (desktop, laptop, VM) and manages user environments via **Home Manager**. The primary desktop environment is built around the **Hyprland** compositor.

**Key Technologies:**
*   **NixOS** & **Nix Flakes**: Core system management and reproducibility.
*   **Home Manager**: User-specific dotfiles and package management.
*   **Hyprland**: Wayland compositor/window manager.
*   **Hyprpanel/Waybar**: Status bars.
*   **Rofi**: Application launcher.
*   **Kitty**: Terminal emulator.
*   **Zsh**: Interactive shell.

## Directory Structure

*   **`flake.nix`**: The entry point for the configuration. Defines inputs (dependencies like `nixpkgs`, `home-manager`, `hyprland`) and outputs (system configurations).
*   **`hosts/`**: Contains machine-specific configurations.
    *   `desktop/`: Configuration for the desktop machine (Nvidia drivers, virtualization).
    *   `laptop/`: Configuration for the laptop (Intel graphics).
    *   `vm/`: Configuration for virtual machines.
*   **`home/`**: Home Manager modules for user `gustl`.
    *   Contains modules for `hyprland`, `kitty`, `rofi`, `waybar`, `zsh`, etc.
    *   `common.nix`: Shared user configuration.
*   **`system/`**: Shared system-level modules.
    *   `common.nix`: Base system settings (locale, networking, users).
    *   `gui.nix`, `cuda.nix`, `sddm/`: Modular system features.
*   **`cfgs/`**: Application-specific raw configuration files (e.g., Rofi themes).
*   **`scripts/`**: Custom shell scripts (background selector, keybind display, clipboard manager).
*   **`wallpapers/`**: Image assets for desktop backgrounds.

## Building and Running

### System Configuration
To apply the system configuration for a specific host:

```bash
# For a fresh install
sudo nixos-install --flake .#<hostname>

# To switch on an existing system
sudo nixos-rebuild switch --flake .#<hostname>
```
*Replace `<hostname>` with `desktop`, `laptop`, or `vm`.*

### User Configuration (Home Manager)
To apply changes to the user environment:

```bash
home-manager switch --flake .#gustl
```

## Development Conventions

*   **Modularity**: The configuration is heavily modularized. `default.nix` files are used to aggregate imports in directories.
*   **Shared Configuration**: Common settings are extracted into `system/common.nix` (system-wide) and `home/common.nix` (user-level) to maximize code reuse across hosts.
*   **Flake Inputs**: Dependencies are pinned in `flake.lock` to ensure reproducibility.
*   **Hyprland Config**: The Hyprland configuration is split into multiple `.conf` files within `home/hyprland/configs/` and sourced by the main Nix module.
