# WoW MoP 5.4.8 — Legends of Azeroth (серверная структура)

Структура развёрнута по образцу bin/etc/sql/data репозитория
https://github.com/Legends-of-Azeroth/Legends-of-Azeroth-Pandaria-5.4.8

## Дерево
```
server/
├── bin/linux/          # worldserver, authserver, map/vmap/mmap extractor (после сборки)
├── etc/                # worldserver.conf, authserver.conf (+ .dist, конфиг модуля PlayerBots)
├── data/               # Maps/, vmaps/, mmaps/, cameras/, client/, dbcontent_bots/, sql/old/
├── logs/               # логи серверов
└── sql/                # archive / base / old / updates (из репозитория)
```

## Подключённые БД (MariaDB localhost:3306, root/root)
- auth        — база аккаунтов
- characters  — база персонажей
- world       — **требует полный дамп** (из Discord/ресурсов проекта LoA или Skyfire)

## Статус
1. Код склонирован в /workspace/src, CMake сконфигурирован в /workspace/build.
2. Компиляция: `cd /workspace/build && make -j2` (GCC 12.2 ниже рекомендованного 13 — возможны ошибки).
3. После сборки скопировать бинарники в bin/linux/:
   `cp build/server/{worldserver,authserver} server/bin/linux/`
   экстракторы: `build/tools/{mapextract,vmap_extractor,mmap_generator}`
4. Извлечь данные из клиента 5.4.8.18945:
   - `./MapExtractor /path/to/WoW` → data/Maps + data/client
   - `./VMapExtractor4 /path/to/WoW data/Maps data/vmaps`
   - `./mmap_generator data/vmaps data/mmaps`
5. Импортировать дампы world и обновить таблицы: `sql/updates`.
6. Запуск: `cd bin/linux && ./worldserver -c ../../etc/worldserver.conf`

GM-аккаунт: в консоли worldserver: `account create admin pass; account setgmlevel admin 4`
