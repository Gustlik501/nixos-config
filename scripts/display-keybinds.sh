#!/bin/bash
# Script to display Hyprland keybinds using rofi

# Define the keybinds config file
keybinds_conf="$HOME/nixos-config/modules/home/hyprland/hyprland-keybinds.conf"

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

# Combine the contents of the keybinds file and filter for keybinds
# We'll look for lines starting with 'bind'
keybinds=$(cat "$keybinds_conf" | grep -E '^bind')

# Check for any keybinds to display
if [[ -z "$keybinds" ]]; then
    echo "No keybinds found in $keybinds_conf."
    exit 1
fi

# Replace $mainMod with SUPER for display purposes (if used in the future)
display_keybinds=$(echo "$keybinds" | sed 's/\$mainMod/SUPER/g')

# Use rofi to display the keybinds
rofi_theme="$HOME/.config/rofi/config-keybinds.rasi" # Assuming a rofi theme exists or will be created
msg='Searchable Hyprland Keybinds'

echo "$display_keybinds" | rofi -dmenu -i -config "$rofi_theme" -mesg "$msg"