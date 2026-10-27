# sway-rising

Monochrome glass rice for SwayFX 0.6: frosted blur, rounded corners, glow on the focused window, floating waybar pills, translucent rofi / dunst / swaylock.

## Contents
- `.config/sway` – config + `config.d/` (appearance, swayfx effects, workflow), idle/screenshot/mirror scripts
- `.config/waybar`, `.config/rofi`, `.config/dunst`, `.config/swaylock`
- `wallpapers/mono-glow.jpg`

## Keys
- `Super+Shift+W` wallpaper picker, `Super+Shift+S` screenshot menu, `Super+F1` keybinding cheatsheet
- `Super+Shift+B` performance mode (toggle blur + shadows)

## Install
Requires: swayfx, waybar, rofi, dunst, swaylock, swayidle, kitty, JetBrains Mono, Font Awesome 6.

    cp -r .config/* ~/.config/
    mkdir -p ~/Pictures/wallpapers && cp wallpapers/* ~/Pictures/wallpapers/
    ln -sf ~/Pictures/wallpapers/mono-glow.jpg ~/Pictures/wallpapers/current
    swaymsg reload

Waybar is started by sway itself (`/usr/share/sway/config.d/90-bar.conf`); reload its style with `pkill -SIGUSR2 waybar`.
