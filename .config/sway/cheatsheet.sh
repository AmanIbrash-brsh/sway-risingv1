#!/bin/bash
# Shows all sway keybindings in the DMS picker (type to filter, Esc to close)
cat ~/.config/sway/config ~/.config/sway/config.d/*.conf | grep -E '^\s*bindsym' | grep -v -- '--locked' \
  | sed -E 's/^\s*bindsym\s+//; s/(--[a-z-]+(=[^ ]+)?\s+)+//; s/\$mod/Super/g; s/^(\S+)\s+/\1\t→ /' \
  | column -t -s $'\t' | dms dmenu >/dev/null
