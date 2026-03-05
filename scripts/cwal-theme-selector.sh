#!/usr/bin/env bash

themes_dir="$HOME/.config/cwal/themes"
rofi_config="$HOME/.config/rofi/config.rasi"
cwal_config="$HOME/.config/cwal/cwal.ini"
wal_dir="$HOME/.cache/wal"
wallpaper_state="$wal_dir/current_wallpaper"

# Build selectable list with random shortcuts plus all installed theme names.
theme_selection=$(
	{
		echo "random_dark"
		echo "random_light"
		echo "random_all"
		find "$themes_dir/dark" "$themes_dir/light" -maxdepth 1 -type f -name '*.cwal' -printf '%f\n' 2>/dev/null \
			| sed 's/\.cwal$//' \
			| sort -u
	} | rofi -dmenu -i -p "Theme" -config "$rofi_config"
)

# User cancelled the picker.
if [ -z "$theme_selection" ]; then
	exit 0
fi

# Resolve current wallpaper path from reliable sources.
wallpaper_path=""
if [ -f "$wallpaper_state" ]; then
	wallpaper_path="$(head -n 1 "$wallpaper_state")"
fi

if [ -z "$wallpaper_path" ] || [ ! -f "$wallpaper_path" ]; then
	wallpaper_path="$(swww query 2>/dev/null | sed -n 's/^[[:space:]]*image:[[:space:]]*//p' | head -n 1)"
fi

if [ -z "$wallpaper_path" ] || [ ! -f "$wallpaper_path" ]; then
	wallpaper_path="$(sed -n 's/^current_wallpaper[[:space:]]*=[[:space:]]*//p' "$cwal_config" | head -n 1)"
fi

if [ -z "$wallpaper_path" ] || [ ! -f "$wallpaper_path" ]; then
	wallpaper_path="$(rg -o '\"[^\"]+\"' "$HOME/.cache/noctalia/wallpapers.json" 2>/dev/null | tr -d '"' | rg '^/.*\.(png|jpg|jpeg|webp)$' | head -n 1)"
fi

if [ -z "$wallpaper_path" ] || [ ! -f "$wallpaper_path" ]; then
	echo "Could not determine current wallpaper path"
	exit 1
fi

cwal --img "$wallpaper_path" --theme "$theme_selection" --out-dir "$wal_dir" --quiet || exit 1
echo "$wallpaper_path" > "$wallpaper_state"

# cwal rofi templates currently emit doubled braces; normalize for rofi parser.
for rofi_colors in "$wal_dir/colors-rofi-dark.rasi" "$wal_dir/colors-rofi-light.rasi"; do
	if [ -f "$rofi_colors" ]; then
		sed -i 's/{{/{/g; s/}}/}/g' "$rofi_colors"
	fi
done

if command -v pywalfox >/dev/null 2>&1; then
	pywalfox update >/dev/null 2>&1 || true
fi
