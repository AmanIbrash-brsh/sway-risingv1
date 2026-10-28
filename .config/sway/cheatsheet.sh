#!/bin/bash
# Shows all sway keybindings in rofi
cat ~/.config/sway/config ~/.config/sway/config.d/*.conf | grep -E '^\s*bindsym' | grep -v -- '--locked' \
  | sed -E 's/^\s*bindsym\s+//; s/(--[a-z-]+(=[^ ]+)?\s+)+//; s/\$mod/Super/g; s/^(\S+)\s+/\1\t→ /' \
  | column -t -s $'\t' | rofi -dmenu -i -p "Keys" -theme ~/.config/rofi/catppuccin.rasi \
    -theme-str 'window {width: 900px;} listview {lines: 14;} entry {placeholder: "Filter...";}' >/dev/null
