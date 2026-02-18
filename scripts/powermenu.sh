#!/usr/bin/env bash

rofi_config="$HOME/nixos-config/cfgs/rofi/powermenu.rasi"

# Toggle if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
  exit 0
fi

lock_icon="lock"
logout_icon="logout"
reboot_icon="restart_alt"
poweroff_icon="power_settings_new"

choice=$(printf '%s\n%s\n%s\n%s\n' \
  "$lock_icon" \
  "$logout_icon" \
  "$reboot_icon" \
  "$poweroff_icon" | rofi -dmenu -config "$rofi_config")

case "$choice" in
  "$lock_icon")
    if command -v hyprlock > /dev/null 2>&1; then
      hyprlock
    elif command -v swaylock > /dev/null 2>&1; then
      swaylock
    else
      loginctl lock-session
    fi
    ;;
  "$logout_icon")
    if command -v hyprctl > /dev/null 2>&1; then
      hyprctl dispatch exit
    else
      loginctl terminate-user "$USER"
    fi
    ;;
  "$reboot_icon")
    systemctl reboot
    ;;
  "$poweroff_icon")
    systemctl poweroff
    ;;
  *)
    exit 0
    ;;
esac
