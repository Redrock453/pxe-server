#!/bin/bash
# Скрипт загрузки Ubuntu netboot installer

set -e

echo "=== Загрузка Ubuntu 20.04 netboot installer ==="

UBUNTU_URL="http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot"

# Загрузка файлов для TFTP
echo "[1/3] Загрузка ядра и initrd для TFTP..."
sudo wget -q --show-progress "${UBUNTU_URL}/ubuntu-installer/amd64/linux" \
  -O /srv/tftp/ubuntu-installer/amd64/linux
sudo wget -q --show-progress "${UBUNTU_URL}/ubuntu-installer/amd64/initrd.gz" \
  -O /srv/tftp/ubuntu-installer/amd64/initrd.gz

# Загрузка полного netboot для HTTP
echo "[2/3] Загрузка полного netboot архива..."
cd /tmp
sudo wget -q --show-progress "${UBUNTU_URL}/netboot.tar.gz"

echo "[3/3] Распаковка в HTTP директорию..."
cd /var/www/html/ubuntu
sudo tar -xzf /tmp/netboot.tar.gz
sudo rm /tmp/netboot.tar.gz

echo ""
echo "=== Загрузка завершена! ==="
echo ""
echo "Файлы готовы:"
echo "  TFTP: /srv/tftp/ubuntu-installer/amd64/"
echo "  HTTP: /var/www/html/ubuntu/"
echo ""
echo "Теперь можно загружать клиенты по PXE!"
echo ""
