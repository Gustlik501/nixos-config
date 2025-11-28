#!/usr/bin/env bash

# Get the list from cliphist and pipe to rofi
if selection=$(cliphist list | rofi -dmenu -p "Clipboard"); then
    # If a selection was made (exit code 0 from rofi), decode and copy
    if [ -n "$selection" ]; then
        echo "$selection" | cliphist decode | wl-copy
    fi
fi