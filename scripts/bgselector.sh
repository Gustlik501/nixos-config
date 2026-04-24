#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

wall_dir="${NIXOS_WALLPAPER_DIR:-$XDG_DATA_HOME/nixos/wallpapers}"
rofi_config="${NIXOS_ROFI_BGSELECTOR_CONFIG:-$XDG_CONFIG_HOME/rofi/nixos/bgselector.rasi}"
cache_dir="$XDG_CACHE_HOME/thumbnails/bgselector"
wal_dir="$XDG_CACHE_HOME/wal"

if [ ! -d "$wall_dir" ]; then
	echo "Wallpaper directory not found: $wall_dir" >&2
	exit 1
fi

mkdir -p "$cache_dir" "$wal_dir"

set_wallpaper() {
	local image="$1"

	if command -v awww >/dev/null 2>&1; then
		if ! pgrep -x awww-daemon >/dev/null 2>&1; then
			awww-daemon --quiet >/dev/null 2>&1 &
			sleep 0.2
		fi

		awww img "$image" --transition-type grow --transition-duration 1 --transition-fps 75
		return
	fi

	if command -v swww >/dev/null 2>&1; then
		if ! pgrep -x swww-daemon >/dev/null 2>&1; then
			swww-daemon >/dev/null 2>&1 &
			sleep 0.2
		fi

		swww img "$image" -t grow --transition-duration 1 --transition-fps 75
		return
	fi

	echo "Neither awww nor swww is installed." >&2
	return 1
}

# Generate thumbnails
find -L "$wall_dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | while read -r imagen; do
	filename="$(basename "$imagen")"
	thumb="$cache_dir/$filename"
	if [ ! -f "$thumb" ]; then
		magick "$imagen" -strip -thumbnail x540^ -gravity center -extent 262x540 "$thumb"
	fi
done

# List wallpapers with icons for rofi
wall_selection=$(
	find -L "$wall_dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -printf '%f\n' \
		| sort \
		| while read -r A; do echo -en "$A\x00icon\x1f$cache_dir/$A\n"; done \
		| rofi -dmenu -config "$rofi_config"
)

# Set wallpaper and regenerate colors
if [ -n "$wall_selection" ]; then
	selected_wall="$wall_dir/$wall_selection"
	if ! set_wallpaper "$selected_wall"; then
		exit 1
	fi
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
