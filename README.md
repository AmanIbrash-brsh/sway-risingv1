# sway-rising

Монохромный «стеклянный» райс для **SwayFX 0.6**: матовый blur, скруглённые углы, мягкое свечение у активного окна, плавающие «острова» в waybar, полупрозрачные rofi / dunst / swaylock.

## Что внутри

| Путь | Что это |
|---|---|
| `.config/sway/config.d/10-appearance.conf` | цвета, рамки, отступы, обои, swayidle (через `idle.sh`) |
| `.config/sway/config.d/20-swayfx.conf` | эффекты SwayFX: blur, тени, скругления, прозрачность, layer_effects |
| `.config/sway/config.d/30-workflow.conf` | хоткеи и помощники (scratchpad, скриншоты, обои, шпаргалка) |
| `.config/sway/*.sh` | `wallpaper.sh`, `screenshot-menu.sh`, `screenshot.sh`, `cheatsheet.sh`, `idle.sh`, `mirror.sh` |
| `.config/waybar` | стеклянные плашки, выдвижной блок железа, mpris, яркость, idle-inhibitor |
| `.config/rofi` | полупрозрачная тема + меню выключения |
| `.config/dunst` | полупрозрачные уведомления со скруглением |
| `.config/swaylock` | локскрин с обоями |
| `wallpapers/` | `original.jpg` (основные), `mono-glow`, `mono-orb`, `mono-smoke`, `mono-grid`, `mono-dusk` |

### Что было добавлено
- **Blur 4 прохода** + brightness / contrast / saturation, шум; свечение у фокусного окна, тёмная тень у остальных.
- **Waybar:** стеклянные плашки, растягивающийся активный воркспейс, модули mpris, backlight, temperature, idle-inhibitor, выдвижной блок `⚙` (температура / CPU / RAM), мигание при низком заряде.
- **Rofi и dunst** сделаны полупрозрачными, чтобы под ними был виден blur.
- **Выбор обоев** с превью (rofi), 6 обоев в наборе.
- **Меню скриншотов** (область / экран, в буфер / в файл).
- **Шпаргалка по хоткеям** прямо из конфига.
- **Режим производительности:** переключатель blur и теней.
- **swayidle:** блокировка через 5 мин, экран гаснет через 10 мин.
- **Swaylock** с обоями и полупрозрачным индикатором.

## Важные хоткеи (`Super` = Mod4)

| Клавиши | Действие |
|---|---|
| `Super+Return` | терминал (kitty) |
| `Super+D` | запуск приложений (rofi) |
| `Super+Shift+Q` | закрыть окно |
| `Super+Shift+C` | перезагрузить конфиг |
| `Super+Shift+E` | выйти из sway |
| `Super+Shift+X` | заблокировать экран |
| `Super+Shift+P` | меню выключения |
| `Super+F1` | **шпаргалка по всем хоткеям** |
| `Super+Shift+W` | выбор обоев |
| `Super+Shift+S` | меню скриншотов |
| `Shift+Print` / `Super+Print` | область → буфер / область → файл |
| `Super+Shift+B` | режим производительности (blur + тени) |
| `Super+`` ` | выпадающий терминал (scratchpad) |
| `Super+H/J/K/L` | фокус влево / вниз / вверх / вправо |
| `Super+Shift+H/J/K/L` | переместить окно |
| `Super+1…0` / `Super+Shift+1…0` | воркспейс / переместить окно на воркспейс |
| `Super+Tab` / `Super+Shift+Tab` | следующий / предыдущий воркспейс |
| `Super+F` | полный экран |
| `Super+Shift+Space` | плавающее окно вкл/выкл |
| `Super+Shift+F` | плавающее 1000×600 по центру |
| `Super+C` | центрировать плавающее окно |
| `Super+R` | режим изменения размера (`H/J/K/L`, `Esc`) |
| `Super+S` / `Super+W` / `Super+E` | layout: stacking / tabbed / split |
| `Alt+Shift` | переключение раскладки (us / ru) |

## Установка

Нужны: swayfx, waybar, rofi, dunst, swaylock, swayidle, kitty, grim, slurp, wl-clipboard, playerctl, brightnessctl, JetBrains Mono, Font Awesome 6.

```sh
cp -r .config/* ~/.config/
mkdir -p ~/Pictures/wallpapers && cp wallpapers/* ~/Pictures/wallpapers/
ln -sf ~/Pictures/wallpapers/original.jpg ~/Pictures/wallpapers/current
swaymsg reload
```

Waybar запускает сам sway (`/usr/share/sway/config.d/90-bar.conf`). Руками его запускать не нужно, иначе будет два бара. Перезагрузка стиля: `pkill -SIGUSR2 waybar`.
