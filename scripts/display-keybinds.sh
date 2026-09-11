#!/usr/bin/env bash
# Display the active shortcuts, including descriptions from the Lua config.
set -o pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

keybinds=$(hyprctl -j binds | python3 -c '
import json
import sys

modifiers = [(64, "Super"), (4, "Ctrl"), (8, "Alt"), (1, "Shift")]
key_names = {
    "RETURN": "Enter", "SPACE": "Space", "TAB": "Tab",
    "LEFT": "Left", "RIGHT": "Right", "UP": "Up", "DOWN": "Down",
    "BRACKETLEFT": "[", "BRACKETRIGHT": "]", "PERIOD": ".", "COMMA": ",",
    "MOUSE:272": "Left click", "MOUSE:273": "Right click",
    "MOUSE_DOWN": "Scroll down", "MOUSE_UP": "Scroll up",
}
for bind in json.load(sys.stdin):
    description = bind.get("description", "")
    if not description:
        continue
    key = bind.get("key", "")
    code = bind.get("keycode", 0)
    # The workspace bindings use XKB keycodes for the number row.
    if code:
        key = str((code - 9) % 10) if 10 <= code <= 19 else f"code:{code}"
    key = key_names.get(key.upper(), key)
    keys = [name for mask, name in modifiers if bind.get("modmask", 0) & mask]
    keys.append(key)
    shortcut = " + ".join(keys)
    if bind.get("submap"):
        shortcut = "[" + bind["submap"] + "] " + shortcut
    print(f"{shortcut:<30}  {description}")
') || exit 1

# Check for any keybinds to display
if [[ -z "$keybinds" ]]; then
    echo "No described keybinds found in the active Hyprland session." >&2
    exit 1
fi

# Use your main rofi config so the theme matches the rest of your setup
rofi_config="$XDG_CONFIG_HOME/rofi/config.rasi"

printf '%s\n' "$keybinds" | rofi -dmenu -i -no-custom -p "Shortcuts" -config "$rofi_config" >/dev/null || true
