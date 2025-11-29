#!/bin/bash
# Скрипт установки и настройки PXE сервера

set -e

echo "=== Установка PXE сервера ==="

# Установка пакетов
echo "[1/6] Установка необходимых пакетов..."
sudo apt update
sudo apt install -y dnsmasq pxelinux syslinux-common nginx memtest86+

# Создание директорий
echo "[2/6] Создание директорий..."
sudo mkdir -p /srv/tftp/pxelinux.cfg
sudo mkdir -p /srv/tftp/ubuntu-installer/amd64
sudo mkdir -p /var/www/html/ubuntu

# Копирование PXE файлов
echo "[3/6] Копирование загрузочных файлов..."
sudo cp /usr/lib/PXELINUX/pxelinux.0 /srv/tftp/
sudo cp /usr/lib/syslinux/modules/bios/*.c32 /srv/tftp/
sudo cp /boot/memtest86+.bin /srv/tftp/memtest

# Копирование конфигураций
echo "[4/6] Применение конфигураций..."
sudo cp configs/dnsmasq-pxe.conf /etc/dnsmasq.d/pxe.conf
sudo cp configs/pxelinux-default.cfg /srv/tftp/pxelinux.cfg/default

# Настройка сети
echo "[5/6] Настройка сети и NAT..."
# Включить IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

# Настройка NAT (замените usb0 на ваш интерфейс)
read -p "Введите интерфейс с интернетом (usb0/wlo1/eth0): " INET_IF
sudo iptables -t nat -A POSTROUTING -o $INET_IF -j MASQUERADE
sudo iptables -A FORWARD -i enp0s25 -o $INET_IF -j ACCEPT
sudo iptables -A FORWARD -i $INET_IF -o enp0s25 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Сохранение правил
sudo apt install -y iptables-persistent
sudo netfilter-persistent save

# Настройка сетевого интерфейса
echo "[6/6] Настройка сетевого интерфейса..."
nmcli connection show "Direct-Connection" &>/dev/null || \
nmcli connection add type ethernet con-name "Direct-Connection" \
  ifname enp0s25 ipv4.method manual ipv4.addresses 192.168.100.1/24

# Запуск сервисов
echo "Запуск сервисов..."
sudo systemctl enable dnsmasq nginx
sudo systemctl restart dnsmasq nginx

echo ""
echo "=== Установка завершена! ==="
echo ""
echo "PXE сервер настроен и запущен на интерфейсе enp0s25"
echo "IP адрес: 192.168.100.1"
echo "DHCP диапазон: 192.168.100.10-100"
echo ""
echo "Для загрузки Ubuntu выполните:"
echo "  bash download-ubuntu.sh"
echo ""
