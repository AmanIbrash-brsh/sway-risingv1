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
| `.config/kitty/kitty.conf` | прозрачность терминала, чтобы был виден blur |
| `.config/sway/config.d/40-bar.conf` | запуск waybar (без `sway-config-fedora`) |
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
- **Swaylock-effects:** размытый скриншот экрана, виньетка, часы и дата. Запускается через `sway/lock.sh`. Если swaylock-effects не установлен, используется обычный swaylock.

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
| ``Super+` `` | выпадающий терминал (scratchpad) |
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

## Установка одной командой (Fedora)

```sh
git clone git@git.ibrash.duckdns.org:aibrash/sway-rising.git && cd sway-rising
./install.sh
```

Скрипт:
1. ставит недостающие пакеты через `dnf` (swayfx берёт из COPR `swayfx/swayfx`, шрифты, waybar, rofi и остальное);
2. кладёт `swaylock-effects` из COPR `pheeef/swaylock-effects` в `~/.local/bin` рядом с системным swaylock и ничего не заменяет (`dnf swap` не проходит из-за `sway-config-fedora`);
3. **делает бэкап** ваших текущих конфигов в `~/rice-backup-<дата>`;
4. копирует конфиги и обои, проверяет конфиг (`sway -C`) и перезагружает sway.

Можно запускать повторно. Перед подключением каждого COPR скрипт спрашивает подтверждение.

Флаги: `--yes` (не спрашивать), `--no-packages` (только конфиги), `--no-lock-effects`.

Waybar запускает сам sway (`config.d/40-bar.conf`). Руками его запускать не нужно, иначе будет два бара. Перезагрузка стиля: `pkill -SIGUSR2 waybar`.
