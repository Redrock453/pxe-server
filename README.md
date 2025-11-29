# PXE Сервер для установки Ubuntu по сети

Документация по настроенному PXE серверу для загрузки и установки Ubuntu через сетевой кабель.

## Что настроено

- **DHCP сервер** - автоматическая выдача IP адресов клиентам
- **TFTP сервер** - раздача загрузочных файлов (ядро, initrd, меню)
- **HTTP сервер (nginx)** - раздача установочных файлов Ubuntu
- **NAT** - раздача интернета со этого компьютера на клиентов
- **PXE Boot** - сетевая загрузка с меню выбора

## Сетевая конфигурация

### Этот компьютер (PXE сервер)
- **Интерфейс:** enp0s25
- **IP адрес:** 192.168.100.1/24
- **Роль:** DHCP, TFTP, HTTP сервер, шлюз

### Клиентские компьютеры
- **IP адреса:** 192.168.100.10 - 192.168.100.100 (выдаются автоматически)
- **Шлюз:** 192.168.100.1
- **DNS:** 8.8.8.8, 8.8.4.4
- **Интернет:** Через NAT на этом компьютере

### Интернет подключение
- **Интерфейс:** usb0 (или wlo1)
- **Используется для:** Раздачи интернета клиентам

## Структура файлов

```
/srv/tftp/                          # TFTP root
├── pxelinux.0                      # PXE загрузчик
├── ldlinux.c32                     # Библиотеки SYSLINUX
├── menu.c32, vesamenu.c32          # Модули меню
├── memtest                         # Memtest86+
├── pxelinux.cfg/
│   └── default                     # Конфигурация PXE меню
└── ubuntu-installer/
    └── amd64/
        ├── linux                   # Ядро Ubuntu (12MB)
        └── initrd.gz               # Initial RAM disk (55MB)

/var/www/html/                      # HTTP root (nginx)
└── ubuntu/                         # Полный netboot installer
    └── ubuntu-installer/
        └── amd64/
            ├── linux
            ├── initrd.gz
            └── ... (остальные файлы установщика)

/etc/dnsmasq.d/
└── pxe.conf                        # Конфигурация DHCP/TFTP
```

## Управление сервисами

### Проверка статуса
```bash
sudo systemctl status dnsmasq       # DHCP + TFTP
sudo systemctl status nginx         # HTTP сервер
```

### Запуск/остановка
```bash
# DHCP + TFTP
sudo systemctl start dnsmasq
sudo systemctl stop dnsmasq
sudo systemctl restart dnsmasq

# HTTP сервер
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
```

### Просмотр логов
```bash
# Логи DHCP/TFTP в реальном времени
sudo journalctl -u dnsmasq -f

# Последние 50 строк логов
sudo journalctl -u dnsmasq -n 50

# Логи HTTP сервера
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## Как использовать

### 1. Подготовка сервера
```bash
# Убедитесь что сервисы запущены
sudo systemctl start dnsmasq
sudo systemctl start nginx

# Проверьте что IP forwarding включен
sysctl net.ipv4.ip_forward
# Должно быть: net.ipv4.ip_forward = 1

# Проверьте NAT правила
sudo iptables -t nat -L POSTROUTING
```

### 2. Подключение клиента
1. Соедините компьютеры **Ethernet кабелем**
2. На клиенте перезагрузитесь
3. При загрузке нажмите клавишу Boot Menu (F12, F9, F10, ESC)
4. Выберите **PXE Boot** или **Network Boot**
5. Клиент получит IP и загрузит меню

### 3. Установка Ubuntu
1. В PXE меню выберите **Install Ubuntu**
2. Следуйте инструкциям установщика
3. Создайте пользователя и пароль
4. Дождитесь завершения установки (~20-30 минут)

## Настройка NAT (раздача интернета)

### Включение IP forwarding
```bash
# Временно (до перезагрузки)
sudo sysctl -w net.ipv4.ip_forward=1

# Постоянно
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Настройка iptables NAT
```bash
# Замените usb0 на ваш интернет-интерфейс
sudo iptables -t nat -A POSTROUTING -o usb0 -j MASQUERADE
sudo iptables -A FORWARD -i enp0s25 -o usb0 -j ACCEPT
sudo iptables -A FORWARD -i usb0 -o enp0s25 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Сохранить правила (Ubuntu)
sudo apt install iptables-persistent
sudo netfilter-persistent save
```

## Редактирование PXE меню

Файл: `/srv/tftp/pxelinux.cfg/default`

```bash
# Редактировать меню
sudo nano /srv/tftp/pxelinux.cfg/default

# После изменений - не нужно перезапускать сервисы
# Изменения применятся при следующей загрузке клиента
```

### Пример конфигурации меню
```
DEFAULT ubuntu-install
TIMEOUT 50

LABEL ubuntu-install
  KERNEL ubuntu-installer/amd64/linux
  APPEND initrd=ubuntu-installer/amd64/initrd.gz nomodeset vga=normal

LABEL memtest
  KERNEL memtest

LABEL local
  LOCALBOOT 0
```

## Решение проблем

### Клиент не получает IP адрес
```bash
# Проверьте что dnsmasq запущен
sudo systemctl status dnsmasq

# Проверьте что интерфейс UP
ip link show enp0s25

# Проверьте логи
sudo journalctl -u dnsmasq -n 50
```

### Мигающий экран при загрузке
Добавьте в APPEND параметры:
```
nomodeset vga=normal fb=false
```

### Нет интернета на клиенте
```bash
# Проверьте IP forwarding
sysctl net.ipv4.ip_forward

# Проверьте NAT правила
sudo iptables -t nat -L POSTROUTING -v

# Проверьте что клиент получил DNS
# На клиенте: cat /etc/resolv.conf
```

### Файлы не скачиваются
```bash
# Проверьте TFTP сервер
sudo journalctl -u dnsmasq | grep tftp

# Проверьте права доступа
ls -la /srv/tftp/

# Проверьте HTTP сервер
curl http://192.168.100.1/ubuntu/
```

## Добавление других систем

### Добавить другой дистрибутив
1. Скачайте kernel и initrd в `/srv/tftp/`
2. Добавьте LABEL в `/srv/tftp/pxelinux.cfg/default`
3. Перезагрузите клиента

### Пример для Debian
```bash
cd /srv/tftp
sudo mkdir debian-installer
sudo wget http://ftp.debian.org/debian/dists/stable/main/installer-amd64/current/images/netboot/debian-installer/amd64/linux -O debian-installer/linux
sudo wget http://ftp.debian.org/debian/dists/stable/main/installer-amd64/current/images/netboot/debian-installer/amd64/initrd.gz -O debian-installer/initrd.gz
```

Добавить в меню:
```
LABEL debian
  KERNEL debian-installer/linux
  APPEND initrd=debian-installer/initrd.gz
```

## Конфигурационные файлы

### /etc/dnsmasq.d/pxe.conf
```
port=0
interface=enp0s25
dhcp-range=192.168.100.10,192.168.100.100,12h
dhcp-boot=pxelinux.0
dhcp-option=6,8.8.8.8,8.8.4.4
enable-tftp
tftp-root=/srv/tftp
dhcp-option=66,192.168.100.1
dhcp-option=67,pxelinux.0
log-dhcp
log-queries
```

## Полезные команды

```bash
# Узнать MAC адрес клиента
sudo journalctl -u dnsmasq | grep DHCPDISCOVER

# Узнать какие файлы скачивал клиент
sudo journalctl -u dnsmasq | grep "sent /srv"

# Проверить сетевые подключения
ip addr show
ip route show

# Проверить открытые порты
sudo netstat -ulnp | grep -E '(67|69|80)'

# Проверить активные DHCP аренды
cat /var/lib/misc/dnsmasq.leases
```

## Автозапуск при загрузке

Сервисы уже настроены на автозапуск:
```bash
sudo systemctl enable dnsmasq
sudo systemctl enable nginx
```

## Безопасность

⚠️ **ВАЖНО:**
- PXE сервер не защищён - любой может загрузиться по сети
- NAT открывает доступ в интернет всем клиентам
- Используйте только в доверенной сети
- Для продакшена добавьте фильтрацию по MAC адресам

### Ограничение по MAC адресу
Добавьте в `/etc/dnsmasq.d/pxe.conf`:
```
# Разрешить только определённые MAC адреса
dhcp-host=AA:BB:CC:DD:EE:FF,192.168.100.50
dhcp-ignore=#known
```

## Автор и дата

Настроено: 29 ноября 2025
Система: Ubuntu 20.04 LTS

---

**Если нужна помощь:**
- Логи: `sudo journalctl -u dnsmasq -f`
- Проверка: `sudo systemctl status dnsmasq nginx`
- Тест сети: `ping 192.168.100.1`
