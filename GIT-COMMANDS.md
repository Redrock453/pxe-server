# Git команды для PXE Server репозитория

## Текущий статус репозитория

Репозиторий инициализирован и содержит первый коммит.

```bash
cd ~/pxe-server-config
git status
git log
```

## Отправка на GitHub/GitLab

### 1. Создайте репозиторий на GitHub/GitLab
- Зайдите на GitHub.com или GitLab.com
- Создайте новый репозиторий (например: `pxe-server-config`)
- **НЕ** инициализируйте с README (у нас уже есть)

### 2. Добавьте remote и отправьте

**Для GitHub:**
```bash
cd ~/pxe-server-config
git remote add origin https://github.com/ВАШ_ЮЗЕР/pxe-server-config.git
git branch -M main
git push -u origin main
```

**Для GitLab:**
```bash
cd ~/pxe-server-config
git remote add origin https://gitlab.com/ВАШ_ЮЗЕР/pxe-server-config.git
git branch -M main
git push -u origin main
```

**Локальный git сервер:**
```bash
# На сервере
mkdir -p /srv/git/pxe-server.git
cd /srv/git/pxe-server.git
git init --bare

# На этом компьютере
cd ~/pxe-server-config
git remote add origin ssh://user@server/srv/git/pxe-server.git
git push -u origin master
```

## Обычные git операции

### Внесение изменений
```bash
cd ~/pxe-server-config

# Изменить файлы
nano configs/dnsmasq-pxe.conf

# Проверить изменения
git status
git diff

# Добавить и закоммитить
git add .
git commit -m "Описание изменений"

# Отправить на сервер (если настроен remote)
git push
```

### Просмотр истории
```bash
# Список коммитов
git log

# Краткая история
git log --oneline

# История с графом
git log --graph --oneline --all

# Изменения в конкретном коммите
git show COMMIT_HASH
```

### Откат изменений
```bash
# Откатить незакоммиченные изменения
git checkout -- filename

# Вернуться к предыдущему коммиту
git revert HEAD

# Жёсткий откат (ОСТОРОЖНО!)
git reset --hard HEAD~1
```

## Клонирование репозитория

На другом компьютере:
```bash
# С GitHub/GitLab
git clone https://github.com/ВАШ_ЮЗЕР/pxe-server-config.git
cd pxe-server-config

# Запустить установку
bash setup.sh

# Скачать Ubuntu
bash download-ubuntu.sh
```

## Теги и релизы

```bash
# Создать тег
git tag -a v1.0 -m "Первая рабочая версия"

# Отправить теги
git push origin --tags

# Список тегов
git tag -l
```

## Полезные алиасы

Добавьте в `~/.gitconfig`:
```ini
[alias]
    st = status
    ci = commit
    co = checkout
    br = branch
    lg = log --graph --oneline --all
    last = log -1 HEAD
```

Теперь можно использовать:
```bash
git st      # вместо git status
git ci      # вместо git commit
git lg      # красивый лог
```

## Структура репозитория

```
pxe-server-config/
├── configs/
│   ├── dnsmasq-pxe.conf       # Конфигурация DHCP/TFTP
│   └── pxelinux-default.cfg   # PXE меню
├── docs/                      # Дополнительная документация
├── setup.sh                   # Скрипт установки
├── download-ubuntu.sh         # Скрипт загрузки Ubuntu
├── README.md                  # Основная документация
├── GIT-COMMANDS.md           # Эта инструкция
└── .gitignore                # Игнорируемые файлы
```

## Бэкап без git

Если не хотите использовать GitHub/GitLab:
```bash
# Создать архив
cd ~
tar -czf pxe-server-backup-$(date +%Y%m%d).tar.gz pxe-server-config/

# Восстановить
tar -xzf pxe-server-backup-YYYYMMDD.tar.gz
```
