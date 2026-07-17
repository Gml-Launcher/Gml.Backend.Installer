> [!WARNING]
> Linux-скрипты `installer.sh`, `updater.sh` и `deleted.sh` устарели и больше не поддерживаются. Для установки, обновления и удаления Gml.Backend на Linux используйте новый [Gml Manager](https://github.com/Gml-Launcher/Gml.Backend#quick-install-with-gml-manager).
>
> Windows-версия [`windows64-installer.bat`](./windows64-installer.bat) в этом репозитории остаётся актуальной.

# Описание репозитория

Этот репозиторий содержит скрипты для установки, обновления и удаления Gml.Backend. Скрипты упрощают процесс управления серверной частью Gml, обеспечивая легкость и удобство выполнения необходимых операций. 

## Установка на русском

Для установки Gml.Backend выполните следующие команды в удобной для вас директории (для работы скрипта необходим `curl`, [инструкция по установке curl](https://losst.pro/ustanovka-curl-v-ubuntu)):

```sh
curl -O https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend.Installer/refs/heads/master/installer.sh
chmod +x ./installer.sh
./installer.sh --version v2025.3.3.2
```

## Обновление

Для обновления Gml.Backend выполните следующую команду в директории, где находятся файлы `docker-compose.yml` и `.env`:

```sh
curl -O https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend.Installer/refs/heads/master/updater.sh
chmod +x ./updater.sh
./updater.sh --version v2025.3.3.2
```



## Удаление

Для удаления Gml.Backend выполните следующую команду в директории, где находятся файлы `docker-compose.yml` и `.env`:

```sh
curl -s https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend.Installer/refs/heads/master/deleted.sh | sh
```

## Преимущества

- **Простота установки**: Установка Gml.Backend осуществляется в несколько команд.
- **Удобное обновление**: Легкое обновление сервера с помощью одной команды.
- **Быстрое удаление**: Возможность удаления всей серверной части также в одну команду.
- **Автоматизация**: Скрипты обеспечивают автоматизацию рутинных задач по управлению серверной частью.

Этот репозиторий предназначен для тех, кто хочет упростить управление своим сервером Gml.Backend, минимизируя ручные операции и возможные ошибки.
