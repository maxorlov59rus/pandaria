# Сборка сервера Pandaria 5.4.8 под Microsoft Windows (MSVC)

Репозиторий: https://github.com/Legends-of-Azeroth/Legends-of-Azeroth-Pandaria-5.4.8

Проект уже содержит полную поддержку Windows: `cmake/platform/win/settings.cmake`,
CI-конфиг `.github/workflows/windows-build-release.yml` (windows-2022 + VS2022).
Ниже — портированный порядок сборки и готовые скрипты.

## 0. Поддержка WIN64 (только 64-битная сборка)

Сборка сервера под Windows поддерживается **исключительно для платформы WIN64 (x64)**:

* `cmake/macros/CheckPlatform.cmake` — при `WIN32` определяет `_WIN64` для всех компиляторов
  (MSVC определяет его сам, MinGW-w64 — не всегда) и выдаёт `FATAL_ERROR`, если обнаружен
  32-битный (`Win32`) toolchain;
* `cmake/platform/win/settings.cmake` — дополнительно определяет макросы `WIN64` и `_WIN64`
  (совместимость со сторонними заголовками, проверяющими классический `WIN64`);
* `cmake/compiler/msvc/settings.cmake` — сохраняет `/bigobj` и `-D_WIN64` для x64;
* версия в логах сервера печатается как `(Win64, little-endian)` — см. `src/server/shared/SystemConfig.h`;
* `build_windows.bat` — настраивает сборку строго через `-A x64`, автоматически удаляет
  build-каталог, сконфигурированный ранее под `Win32`, и проверяет наличие 64-битных
  компонентов OpenSSL (`libcrypto-3-x64.dll` / `libcrypto.lib`) и MySQL SDK.

Все зависимости (Boost, OpenSSL, MySQL/MariaDB Connector) обязаны быть 64-битными (x64).

## 1. Требования (Windows 10/11 x64)

| Компонент | Версия | Установка |
|---|---|---|
| Visual Studio 2022 | Community+ | рабочий компонент «Desktop development with C++» (обязателен MSVC v143, т.к. используется C++20) |
| CMake | >= 3.16 | winget install Kitware.CMake |
| Git for Windows | любая | winget install Git.Git |
| Boost | 1.87.0 | b2 variant=release link=shared runtime-link=shared address-model=64 toolset=msvc (headers + locale, filesystem, iostreams, program_options, regex, system, thread) |
| OpenSSL | 3.1.x (x64) | winget install FireDaemon.OpenSSL или чрез shaiululd choco: `choco install -y openssl --version=3.1.1` |
| MySQL / MariaDB Connector/C | 8.0 x64 (libmysql.dll + include) | установщик MySQL Server (Developer Component) или MariaDB Connector/C |
| Python 3 | любая | нужна для contrib/extractors |

Проверка окружения: `build_windows.bat` запускает `cmake --version` и ловит отсутствующие инструменты.

## 2. Автоматическая сборка

Из корня репозитория (папка с `CMakeLists.txt`) выполнить:

```bat
build_windows.bat
```

Скрипт делает:
1. `cmake -S . -B build -A x64 -DTOOLS=ON -DELUNA=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
   -DBOOST_ROOT=%BOOST_ROOT% -DOPENSSL_ROOT_DIR=%OPENSSL_ROOT_DIR% ^
   -DMYSQL_INCLUDE_DIR=%MYSQL_INCLUDE_DIR% -DMYSQL_LIBRARY=%MYSQL_LIBRARY%`
2. `cmake --build build --config RelWithDebInfo --parallel %NUMBER_OF_PROCESSORS%`
3. Копирует бинарники в `server\bin\windows\`, DLL (`libmysql.dll`, `libcrypto-3-x64.dll`,
   `libssl-3-x64.dll`) рядом с ними, а `contrib/lua_scripts` — в папку запуска.

Переменные путей к зависимостям можно задать перед запуском, иначе используются
типовые пути установки (см. начало скрипта).

Альтернатива через Visual Studio: открыть папку исходников как проект CMake
(`CMakeSettings.json` уже содержит конфигурацию `x64-Release`).

## 3. Ручная сборка (эквивалент CI windows-build-release)

```bat
mkdir build && cd build
cmake .. -G "Visual Studio 17 2022" -A x64 -DTOOLS=ON -DELUNA=1 ^
  -DBOOST_ROOT=C:\Libraries\boost_1_87_0 ^
  -DOPENSSL_ROOT_DIR="C:\Program Files\OpenSSL-Win64"
cmake --build . --config RelWithDebInfo --parallel 4
```

Результат: `build\bin\RelWithDebInfo\{authserver,worldserver,*.exe}`.

Обязательно положить рядом с exe:
- `libmysql.dll` (из `C:\Program Files\MySQL\MySQL Server 8.0\lib\`)
- `libcrypto-3-x64.dll`, `libssl-3-x64.dll` (из OpenSSL bin)

## 4. Отличия Windows-сборки от Linux

* Генератор — Visual Studio (многоконфигурационный): выход лежит в `bin/<Config>/`.
* Коннектор к БД — динамический `libmysql.dll` (MariaDB Connector/C тоже подходит).
* PCH включены (`USE_COREPCH/USE_SCRIPTPCH`), флаги MSVC настраивает
  `cmake/compiler/msvc/settings.cmake` (/MP, /bigobj и т.д.).
* Сервисы Windows не регистрируются — запуск `authserver.exe` / `worldserver.exe` из консоли.
* Пути в conf-файлах — в нотации Windows (`data/`, `logs/` относительные допустимы).

## 5. Структура после сборки

```
workspace/
├── src/                  # исходники (CMakeLists, dep, contrib, sql)
│   ├── build_windows.bat # <-- скрипт сборки под Windows
│   └── CMakeSettings.json
├── build/                # linux-артефакты (не трогаем при win-сборке; см. build-win/)
└── server/               # развёртка сервера
    ├── bin/linux/        # elf-бинарники
    ├── bin/windows/      # <-- сюда кладутся .exe и .dll
    ├── etc/              # worldserver.conf, authserver.conf
    ├── data/             # MAP_DATA_DIR (maps, dbc, vmap, cameras)
    ├── logs/
    └── sql/
```

## 6. Запуск на Windows

1. Установить MariaDB/MySQL 8.x, создать БД `auth`, `characters`, `world`
   и импортировать дампы из `src/sql/` (world — дамп проекта LoA).
2. Скопировать `authserver.conf.dist` / `worldserver.conf.dist` в `etc/`,
   убрать суффикс `.dist`, указать строки подключения `LoginDatabaseInfo`.
3. Извлечь карты: `mapextractor.exe`, `vmap4extractor.exe`, `vmap4assembler.exe`,
   `mmaps_generator.exe` (из `bin/windows/tools/`) — результат в `data/`.
4. Запустить `authserver.exe`, затем `worldserver.exe`; создать GM: `.account create` / `.gm`.
