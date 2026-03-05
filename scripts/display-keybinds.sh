#!/usr/bin/env bash
# Script to display Hyprland keybinds using rofi

# Define the keybinds config file
keybinds_conf="$HOME/nixos-config/home/hyprland/configs/UserKeybinds.conf"

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

# Filter keybind definitions
keybinds=$(rg '^bind' "$keybinds_conf")

# Check for any keybinds to display
if [[ -z "$keybinds" ]]; then
    echo "No keybinds found in $keybinds_conf."
    exit 1
fi

# Replace $mainMod with SUPER for display purposes (if used in the future)
display_keybinds=$(echo "$keybinds" | sed 's/\$mainMod/SUPER/g')

# Use your main rofi config so the theme matches the rest of your setup
rofi_config="$HOME/.config/rofi/config.rasi"

echo "$display_keybinds" | rofi -dmenu -i -p "Search" -config "$rofi_config"
