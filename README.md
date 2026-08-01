# MineGame

Браузерный игровой сервер на базе Minetest/Luanti и игры VoxeLibre (открытая реализация Minecraft), доступный прямо из браузера через WebAssembly-клиент, без установки.

## Структура репозитория

### `paradust-wasm/`
WASM-сборка клиента Minetest (форк [paradust7/minetest-wasm](https://github.com/paradust7/minetest-wasm)), позволяющая запускать игру прямо в браузере через emscripten.

- `sources/minetest/` — форк движка Luanti с внесёнными правками (см. раздел «Кастомные изменения» ниже)
- `static/` — веб-страница запуска игры (`index.html`, `launcher.js`) со стартовым экраном выбора языка и прокси
- `common.sh`, `fetch_sources.sh`, `incremental.sh`, `install_emsdk.sh` — скрипты сборки

Зависимости для сборки (`emsdk/`, чужие библиотеки `zlib`, `libpng`, `libjpeg`, `freetype`, `zstd`, `minetest_game`) не включены в репозиторий — их можно получить через `fetch_sources.sh` и `install_emsdk.sh`.

### `voxelibre/`
Актуальная копия игры VoxeLibre, которая реально исполняется на сервере — включая все кастомные моды и правки геймплея.

### `minetest-server/`
Конфигурация серверной части:
- `config/minetest.conf` — основной конфиг сервера (секретный токен Laravel API заменён на плейсхолдер `YOUR_SECRET_TOKEN_HERE` — реальное значение хранится только на боевом сервере)
- `worldmods/auth_laravel/` — кастомный мод авторизации через внешний Laravel API вместо стандартной системы Minetest
- `world.mt.example` — пример конфигурации мира

## Архитектура проекта

### База проекта

- **Игра:** [VoxeLibre](https://content.luanti.org/packages/Wuzzy/mineclone2/) версии **0.87.0** — открытая реализация Minecraft на движке Luanti
- **Движок:** [Luanti (бывш. Minetest)](https://www.luanti.org/) версии **5.14.0**
- **Браузерная сборка:** форк [paradust7/minetest-wasm](https://github.com/paradust7/minetest-wasm), портирующий движок Luanti в WebAssembly через emscripten

### Что написано с нуля

- `minetest-server/worldmods/auth_laravel/` — мод авторизации через внешний Laravel API вместо стандартной системы логинов Minetest
- `voxelibre/mods/PLAYER/mcl_starterkit/` — выдача стартового набора предметов новым игрокам
- `voxelibre/mods/HELP/mcl_craftguide_autocraft/` — кнопка «Создать» в справочнике рецептов (автоматический крафт из инвентаря)

### Что изменено в движке/игре относительно апстрима

**Движок (`paradust-wasm/sources/minetest`):**
- `src/client/game.cpp` — метод `fogEnabled()` зафиксирован на постоянное `true`; `toggleFog()` обезврежен, чтобы клавиша F3 не могла отключить туман
- `src/client/inputhandler.cpp` — добавлена дополнительная привязка клавиши Tab к открытию инвентаря (в дополнение к стандартной клавише)
- `src/network/clientpackethandler.cpp` — язык клиента теперь берётся из настройки `language` (переданной со стартовой веб-страницы), а не только из `.mo`-файлов, которых нет в WASM-сборке

**Игра (`voxelibre/mods`):**
- `MAPGEN/mcl_biomes/init.lua` — снижена плотность декораций травы и цветов (сдвинуты параметры `offset` у `register_grass_decoration`/`register_doubletall_grass`/`register_flower`)
- `ENTITIES/mcl_mobs/api.lua` — враждебные мобы (`spawn_class == "hostile"`) исключены из принудительного поддержания таймера жизни рядом с игроком, благодаря чему они деспавнятся со временем даже вблизи игрока; животные и прирученные мобы не затронуты
- `ITEMS/mcl_core/functions.lua` — ускорен ABM распада «осиротевшей» листвы после вырубки дерева (`interval`/`chance` в decoration «Leaf decay»)
- Встроенный кастомный anticheat-мод удалён по запросу заказчика

**Конфигурация сервера (`minetest-server/config/minetest.conf`):**
- `mcl_mob_cap_monster = 15`, `mcl_mob_cap_hostile = 80` — снижены лимиты спавна враждебных мобов (были 70 и 300 по умолчанию)

### Как устроена браузерная версия

Клиент Luanti скомпилирован в WebAssembly (emscripten) и запускается прямо в браузере через `<canvas>`. Веб-страница (`paradust-wasm/static/index.html` + `launcher.js`) перед запуском:
1. Даёт выбрать сетевой прокси (WebSocket-туннель до игрового сервера, так как браузер не умеет напрямую открывать UDP-соединения, которые использует протокол Minetest)
2. Даёт выбрать язык интерфейса
3. Формирует `minetest.conf` на лету и передаёт его в WASM-модуль через `emloop_set_minetest_conf`
4. Запускает сам WASM-модуль (`luanti.js` + `luanti.wasm`), который устанавливает WebSocket-соединение с игровым сервером через прокси

Собранные файлы клиента (`paradust-wasm/www/`) — статические файлы, которые можно разместить на любом веб-сервере (nginx и т.п.).

### Как запустить проект на новом сервере

1. Установить `minetestserver` (пакет `minetest-server` в Debian/Ubuntu, либо собрать Luanti 5.14.0 из исходников)
2. Скопировать `voxelibre/` в папку игр Minetest, обычно `/usr/share/games/minetest/games/voxelibre/`
3. Создать мир: `worldpath = <путь>`, `gameid = voxelibre` в конфиге
4. Скопировать `minetest-server/worldmods/auth_laravel/` в папку `worldmods/` созданного мира
5. Взять `minetest-server/config/minetest.conf` за основу, подставить реальный `laravel_server_token` и адрес Laravel API (`laravel_api_url`)
6. Запустить сервер:
   ```
   minetestserver --config minetest-server/config/minetest.conf --gameid voxelibre --world <путь к миру>
   ```
7. Развернуть собранный WASM-клиент (см. ниже) на веб-сервере и настроить WebSocket-прокси до игрового сервера (порт 30000 по умолчанию)

### Как собрать браузерную версию заново

```
cd paradust-wasm
./install_emsdk.sh      # установка Emscripten SDK
./fetch_sources.sh      # загрузка сторонних библиотек (zlib, libpng, libjpeg, freetype, zstd и т.д.)
./build_all.sh          # полная сборка (при последующих правках можно использовать ./incremental.sh)
```
Результат сборки — папка `www/<RELEASE_UUID>/` с `luanti.js`, `luanti.wasm` и сопутствующими файлами, плюс обновлённые `index.html`/`launcher.js` в `www/` с прописанным UUID текущего релиза.

### Где что находится

| Что | Путь на боевом сервере |
|---|---|
| Конфигурация сервера | `/opt/minetest-server/config/minetest.conf` |
| Игра VoxeLibre (исполняемая) | `/usr/share/games/minetest/games/voxelibre/` |
| Мир (карта, данные игроков) | `/home/minetest/.minetest/worlds/voxelibre/` |
| Моды мира (auth_laravel и т.д.) | `/home/minetest/.minetest/worlds/voxelibre/worldmods/` |
| База логинов/паролей | `/home/minetest/.minetest/worlds/voxelibre/auth.sqlite` |
| Собранный WASM-клиент | `/root/paradust-wasm/www/` → раздаётся из `/var/www/luanti/` |
| Исходники WASM-сборки | `/root/paradust-wasm/` |

## Известные особенности

- Смена языка через внутриигровые настройки (не через стартовую веб-страницу) требует полной перезагрузки клиента — это ограничение самого движка Luanti, а не баг
