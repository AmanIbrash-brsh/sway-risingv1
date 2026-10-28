#!/usr/bin/env bash
# Bluetooth menu (rofi): power, connect/disconnect known devices, scan and pair new ones.
THEME=~/.config/rofi/catppuccin.rasi
menu() { rofi -dmenu -i -p "$1" -theme "$THEME" "${@:2}"; }

if ! bluetoothctl show | grep -q "Powered: yes"; then
    choice=$(printf '%s\n' "Включить Bluetooth" | menu "Bluetooth") || exit 0
    [[ $choice == "Включить Bluetooth" ]] && bluetoothctl power on >/dev/null && notify-send "Bluetooth" "Включён"
    exit 0
fi

build() {
    local list="" mac name mark
    while read -r _ mac name; do
        [[ -z $mac ]] && continue
        mark="○"; bluetoothctl info "$mac" | grep -q "Connected: yes" && mark="●"
        list+="$mark $name  [$mac]"$'\n'
    done < <(bluetoothctl devices)
    printf '%s' "$list"
}

choice=$(printf '%s%s\n%s\n' "$(build)" "Найти новые устройства" "Выключить Bluetooth" | sed '/^$/d' | menu "Bluetooth") || exit 0
[[ -z $choice ]] && exit 0

case $choice in
    "Выключить Bluetooth") bluetoothctl power off >/dev/null; notify-send "Bluetooth" "Выключен"; exit 0 ;;
    "Найти новые устройства")
        notify-send "Bluetooth" "Поиск устройств (8 с)…"
        bluetoothctl --timeout 8 scan on >/dev/null 2>&1
        choice=$(build | menu "Bluetooth: найденные") || exit 0
        [[ -z $choice ]] && exit 0
        mac=${choice##*[}; mac=${mac%]}
        bluetoothctl pair "$mac" >/dev/null 2>&1; bluetoothctl trust "$mac" >/dev/null 2>&1
        bluetoothctl connect "$mac" >/dev/null 2>&1 && notify-send "Bluetooth" "Подключено" || notify-send -u critical "Bluetooth" "Не удалось подключиться"
        exit 0 ;;
esac

mac=${choice##*[}; mac=${mac%]}
name=${choice:2}; name=${name%  [*}
if [[ ${choice:0:1} == "●" ]]; then
    bluetoothctl disconnect "$mac" >/dev/null && notify-send "Bluetooth" "Отключено: $name"
else
    bluetoothctl connect "$mac" >/dev/null 2>&1 && notify-send "Bluetooth" "Подключено: $name" || notify-send -u critical "Bluetooth" "Не удалось подключиться: $name"
fi
