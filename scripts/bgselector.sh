#!/usr/bin/env bash

wall_dir="$HOME/nixos-config/wallpapers"
cache_dir="$HOME/.cache/thumbnails/bgselector"
wal_dir="$HOME/.cache/wal"

mkdir -p "$wall_dir"
mkdir -p "$cache_dir"
mkdir -p "$wal_dir"

# Generate thumbnails
find "$wall_dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | while read -r imagen; do
	filename="$(basename "$imagen")"
	thumb="$cache_dir/$filename"
	if [ ! -f "$thumb" ]; then
		magick "$imagen" -strip -thumbnail x540^ -gravity center -extent 262x540 "$thumb"
	fi
done

# List wallpapers with icons for rofi
wall_selection=$(ls "$wall_dir" | while read -r A; do echo -en "$A\x00icon\x1f$cache_dir/$A\n"; done | rofi -dmenu -config "$HOME/nixos-config/cfgs/rofi/bgselector.rasi")

# Set wallpaper and regenerate colors
if [ -n "$wall_selection" ]; then
	selected_wall="$wall_dir/$wall_selection"
	swww img "$selected_wall" -t grow --transition-duration 1 --transition-fps 75
	echo "$selected_wall" > "$wal_dir/current_wallpaper"
	if command -v noctalia-shell >/dev/null 2>&1; then
		noctalia-shell ipc call wallpaper set "$selected_wall" all >/dev/null 2>&1 || true
	fi
	sleep 0.2
	if command -v cwal >/dev/null 2>&1; then
		cwal --img "$selected_wall" --out-dir "$wal_dir" --quiet || true
		for rofi_colors in "$wal_dir/colors-rofi-dark.rasi" "$wal_dir/colors-rofi-light.rasi"; do
			if [ -f "$rofi_colors" ]; then
				sed -i 's/{{/{/g; s/}}/}/g' "$rofi_colors"
			fi
		done
	fi
	if command -v pywalfox >/dev/null 2>&1; then
		pywalfox update >/dev/null 2>&1 || true
	fi
	exit 0
else
	exit 1
fi
