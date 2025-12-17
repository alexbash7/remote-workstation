# Remote Workstation

## Установка

ssh root@IP
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget
cd /root
git clone https://github.com/alexbash7/remote-workstation.git
cd remote-workstation
chmod +x install.sh
./install.sh
sudo reboot


## Подключение VNC (первичная настройка)

macOS: Finder → Cmd+K → vnc://IP:5900
Пароль: из VNC_PASSWORD

## Подключение RustDesk (основной)

Узнать ID: rustdesk --get-id
Скачать клиент: brew install --cask rustdesk
Пароль: из RUSTDESK_PASSWORD

## Отключить VNC после настройки

sudo systemctl disable --now x0vncserver
