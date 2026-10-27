#!/bin/bash
# Wallpaper picker with previews. Also used by sway at start (arg: apply).
dir=$HOME/Pictures/wallpapers
cur=$dir/current
if [ "$1" != apply ]; then
    pick=$(find "$dir" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.png' \) | sort | while read -r f; do
        printf '%s\0icon\x1f%s\n' "$(basename "$f" | sed 's/\.[^.]*$//')" "$f"
    done | rofi -dmenu -i -p "Wallpaper" -show-icons -theme ~/.config/rofi/catppuccin.rasi \
        -theme-str 'window {width: 760px;} listview {columns: 3; lines: 2;} element {orientation: vertical; padding: 10px;} element-icon {size: 9em;} element-text {horizontal-align: 0.5;} entry {enabled: false;}')
    [ -n "$pick" ] || exit 0
    file=$(find "$dir" -maxdepth 1 -type f -name "$pick.*" | head -1)
    ln -sf "$file" "$cur"
fi
swaymsg output '*' bg "$cur" fill >/dev/null
