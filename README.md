# BigWigs for Sirus

**[Русский](#русский) | [English](#english)**

---

## Русский

Порт босс-модов **BigWigs** и **LittleWigs** на сервер **Sirus** (World of Warcraft 3.3.5a).

Тайминги, крики, ID заклинаний и мобов взяты из **DBM Sirus**, поэтому учтены переделанные Sirus рейды, героические
режимы и кастомные боссы. Механики, которых нет в DBM, добавлены по WeakAuras игроков.

Нашли ошибку или неверный таймер — пишите в [Issues](../../issues).

### Что входит

| Аддон | Содержимое |
|---|---|
| `BigWigs`, `BigWigs_Core`, `BigWigs_Plugins`, `BigWigs_Options` | Ядро, полосы, сообщения, звуки, окно близости, настройки |
| `BigWigs_WrathOfTheLichKing` | ЦЛК (с Джайной), Испытание крестоносца, Ульдуар, Наксрамас (с героиком), Ониксия, Око Вечности, Обсидиановое и Рубиновое святилища, Склеп Аркавона, кастомные рейды Sirus (Бронзовое святилище, Тюрьма Тол'Гарод), Норигорн, Зорт |
| `BigWigs_BurningCrusade` | Каражан, Логово Груула, Логово Магтеридона, Змеиное святилище, Око, Хиджал, Чёрный храм, Зул'Аман, Плато Солнечного Колодца |
| `BigWigs_Classic` | Огненные Недра, Логово Крыла Тьмы, Руины и Храм Ан'Киража, Зул'Гуруб |
| `LittleWigs_WrathOfTheLichKing` | Все 16 подземелий WotLK, таймеры треша эпохальных ключей |
| `LittleWigs_BurningCrusade` | Все 16 подземелий BC, аффиксы и таймеры треша эпохальных ключей Sirus, Ахун |

### Установка

1. Скачайте архив: зелёная кнопка **Code** → **Download ZIP** вверху этой страницы
   (или последнюю версию в [Releases](../../releases), если она там есть).
2. Распакуйте архив. Внутри будет папка `BigWigs-for-Sirus-main`.
3. Скопируйте **всё её содержимое** (9 папок `BigWigs…` и `LittleWigs…`) в папку аддонов игры:
   ```
   <папка игры>\Interface\AddOns\
   ```
   Например: `C:\Games\World of Warcraft Sirus\Interface\AddOns\`.
4. Проверьте, что папки лежат **прямо** в `AddOns`. Правильно: `AddOns\BigWigs\BigWigs.toc`.
   Неправильно: `AddOns\BigWigs-for-Sirus-main\BigWigs\…`. Иначе игра не увидит аддон.
5. Если раньше стоял другой BigWigs или LittleWigs, сначала удалите его папки.
6. Запустите игру. На экране выбора персонажа откройте **«Модификации»** и включите все аддоны BigWigs и LittleWigs.
   При необходимости поставьте галочку **«Загружать устаревшие модификации»**.

### Обновление

Удалите старые папки `BigWigs…` и `LittleWigs…` из `Interface\AddOns` и установите новую версию по инструкции выше.
Настройки хранятся в папке `WTF` и сохранятся.

### Использование

| Команда | Что делает |
|---|---|
| `/bw` | Открыть настройки: боссы, полосы, сообщения, звуки. Там же кнопка «Тест» |
| `/range 10` | Окно близости на 10 метров (`/range 0` — закрыть) |
| `/pull 10` | Отсчёт пулла на 10 секунд (виден и игрокам с DBM) |
| `/break 5` | Перерыв на 5 минут |
| `/bwdebug` | Диагностика: зона, сложность, загруженные модули, состояние боя по текущей цели (`/bwdebug off` — выключить) |
| `/bwlog on` | Включить журнал боёв (см. ниже). `/bwlog` — сколько боёв записано, `/bwlog off` — выключить, `/bwlog clear` — стереть записи |

Модули загружаются сами при входе в подземелье или рейд. Модули мировых боссов загружаются, когда босс у вас в цели.

**DBM и WeakAuras.** BigWigs можно держать вместе с DBM, но тогда предупреждения будут дублироваться, поэтому лучше
оставить что-то одно. Отсчёты пулла и перерыва совместимы с DBM в обе стороны. WeakAuras Sirus на общих триггерах
«Boss Mod Timer / Announce / Stage» при установленном BigWigs берут данные из него. Номера способностей и счётчики
в полосах сделаны как в DBM, поэтому большинство таких ВАшек работает. Триггеры «DBM Timer / Announce» без DBM
работать не будут.

### Если что-то не работает

1. Включите показ ошибок Lua: `/console scriptErrors 1`, затем `/reload`.
2. `/bw` → «Тест»: проверьте, что полосы вообще появляются.
3. Возьмите босса в цель и наберите `/bwdebug`. Повторите после начала боя.
4. Создайте [Issue](../../issues): напишите босса, сложность, текст ошибки и вывод `/bwdebug`.

### Журнал боёв: помогите добавить недостающее

Если босс или моб делает что-то важное, а BigWigs об этом молчит, запишите бой — по журналу это можно добавить в аддон.

1. Наберите `/bwlog on` (один раз, настройка запоминается).
2. Пройдите подземелье, ключ или рейд как обычно. Каждый бой записывается отдельно, в подземельях и рейдах.
3. Выйдите из игры или наберите `/reload` — только тогда игра сохраняет запись на диск.
4. Возьмите файл `<папка игры>\WTF\Account\<ВАШ_АККАУНТ>\SavedVariables\BigWigs.lua`, запакуйте его в `.zip`
   (GitHub не принимает файлы `.lua`) и прикрепите к новому [Issue](../../issues).
5. В Issue напишите: подземелье или рейд, сложность, какой босс или моб и что именно не показывалось
   (например: «Крепость Утгард, ключ, третий босс — каст „…“ без предупреждения»).

Что попадает в журнал: только действия мобов и боссов — касты с номерами заклинаний и временем, ауры от мобов, призывы,
смерти, крики и эмоции, сбитые игроками касты мобов, а также что в этот момент показал BigWigs. Действия игроков, удары
оружием, исцеления и каждый тик урона не пишутся. Хранятся последние 40 боёв.

В журнале есть имена игроков вашей группы (цели заклинаний мобов), а в файле — настройки BigWigs и имена ваших
персонажей. Если не хотите ими делиться, сотрите записи перед походом (`/bwlog clear`) и присылайте только нужный бой.

### Благодарности

Оригинальные аддоны [BigWigs](https://github.com/BigWigsMods/BigWigs) и
[LittleWigs](https://github.com/BigWigsMods/LittleWigs) написаны командой BigWigsMods. Данные о боях взяты из DBM
для Sirus, часть механик — из WeakAuras игроков Sirus.

---

## English

A port of the **BigWigs** and **LittleWigs** boss mods to the **Sirus** server (World of Warcraft 3.3.5a).

Timers, yells, spell and NPC IDs come from **DBM for Sirus**. This covers the raids Sirus reworked, its heroic modes
and its custom bosses. Mechanics missing from DBM were added from players' WeakAuras.

Found a bug or a wrong timer? Please report it in [Issues](../../issues).

### What's included

| Addon | Contents |
|---|---|
| `BigWigs`, `BigWigs_Core`, `BigWigs_Plugins`, `BigWigs_Options` | Core, bars, messages, sounds, proximity window, options |
| `BigWigs_WrathOfTheLichKing` | Icecrown Citadel (incl. Jaina), Trial of the Crusader, Ulduar, Naxxramas (incl. Sirus heroic), Onyxia, Eye of Eternity, Obsidian and Ruby Sanctums, Vault of Archavon, Sirus custom raids (Bronze Sanctuary, Tol'Garod Prison), Sirus world bosses (Norigorn, Zort) |
| `BigWigs_BurningCrusade` | Karazhan, Gruul's Lair, Magtheridon's Lair, Serpentshrine Cavern, The Eye, Mount Hyjal, Black Temple, Zul'Aman, Sunwell Plateau |
| `BigWigs_Classic` | Molten Core, Blackwing Lair, Ruins and Temple of Ahn'Qiraj, Zul'Gurub |
| `LittleWigs_WrathOfTheLichKing` | All 16 WotLK dungeons, trash timers for mythic keys |
| `LittleWigs_BurningCrusade` | All 16 TBC dungeons, Sirus mythic key affixes and trash timers, Ahune |

Many texts for the reworked Sirus content exist only in Russian, as in DBM Sirus. The Russian client is the main
target.

### Installation

1. Download the archive: the green **Code** button → **Download ZIP** at the top of this page
   (or the latest version from [Releases](../../releases), if there is one).
2. Extract it. You will get a `BigWigs-for-Sirus-main` folder.
3. Copy **all of its contents** (9 `BigWigs…` and `LittleWigs…` folders) into the game's addon folder:
   ```
   <game folder>\Interface\AddOns\
   ```
   For example `C:\Games\World of Warcraft Sirus\Interface\AddOns\`.
4. Make sure the folders sit **directly** in `AddOns`. Correct: `AddOns\BigWigs\BigWigs.toc`.
   Wrong: `AddOns\BigWigs-for-Sirus-main\BigWigs\…`. Otherwise the game won't see the addon.
5. If you had another BigWigs or LittleWigs installed, delete its folders first.
6. Start the game. On the character select screen open **AddOns** and enable all BigWigs and LittleWigs addons.
   Tick **Load out of date AddOns** if needed.

### Updating

Delete the old `BigWigs…` and `LittleWigs…` folders from `Interface\AddOns` and install the new version as above.
Your settings are stored in the `WTF` folder and are kept.

### Usage

| Command | What it does |
|---|---|
| `/bw` | Open the options: bosses, bars, messages, sounds. The "Test" button is there too |
| `/range 10` | 10-yard proximity window (`/range 0` to close) |
| `/pull 10` | 10-second pull countdown (also shown to DBM users) |
| `/break 5` | 5-minute break |
| `/bwdebug` | Diagnostics: zone, difficulty, loaded modules, fight state for your current target (`/bwdebug off` to disable) |
| `/bwlog on` | Turn on the fight log (see below). `/bwlog` — how many fights are saved, `/bwlog off` — turn off, `/bwlog clear` — delete them |

Modules load by themselves when you enter a dungeon or raid. World boss modules load when you target the boss.

**DBM and WeakAuras.** BigWigs can run next to DBM, but the warnings will be doubled, so it is better to keep only
one. Pull and break timers are compatible with DBM both ways. When BigWigs is installed, WeakAuras Sirus takes the data
for the generic "Boss Mod Timer / Announce / Stage" triggers from it. Ability IDs and bar counters match DBM, so most
of those auras work. "DBM Timer / Announce" triggers will not work without DBM.

### Troubleshooting

1. Turn on Lua errors: `/console scriptErrors 1`, then `/reload`.
2. `/bw` → "Test": check that bars show up at all.
3. Target the boss and type `/bwdebug`. Repeat after the pull.
4. Open an [Issue](../../issues) with the boss, the difficulty, the error text and the `/bwdebug` output.

### Fight log: help add what's missing

If a boss or a mob does something important and BigWigs stays silent, record the fight — the log is enough to add it.

1. Type `/bwlog on` (once, the setting is remembered).
2. Run the dungeon, key or raid as usual. Every fight is saved separately, in dungeons and raids.
3. Log out or type `/reload` — only then the game writes the log to the disk.
4. Take `<game folder>\WTF\Account\<YOUR_ACCOUNT>\SavedVariables\BigWigs.lua`, put it in a `.zip`
   (GitHub doesn't accept `.lua` files) and attach it to a new [Issue](../../issues).
5. In the Issue write the dungeon or raid, the difficulty, the boss or mob and what wasn't shown.

What goes into the log: only the actions of mobs and bosses — casts with spell ids and times, auras from mobs, summons,
deaths, yells and emotes, mob casts interrupted by players, and what BigWigs showed at that moment. Player actions, melee,
heals and every damage tick are left out. The last 40 fights are kept.

The log has the names of your group members (the targets of mob spells), and the file has your BigWigs settings and your
character names. If you don't want to share them, clear the log before the run (`/bwlog clear`).

### Credits

The original [BigWigs](https://github.com/BigWigsMods/BigWigs) and
[LittleWigs](https://github.com/BigWigsMods/LittleWigs) addons are made by the BigWigsMods team. Encounter data comes
from DBM for Sirus, some mechanics from the WeakAuras of Sirus players.
