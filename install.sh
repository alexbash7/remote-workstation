#!/usr/bin/env bash
set -e

echo "=== Remote Workstation bootstrap started ==="

# --- LOAD CONFIG ---
if [ -f ./config.env ]; then
    export $(grep -v '^#' ./config.env | xargs)
else
    echo "config.env not found! Exiting..."
    exit 1
fi

# --- BASIC SYSTEM ---
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  curl \
  wget \
  git \
  unzip \
  nano \
  htop \
  ca-certificates \
  gnupg \
  lsb-release \
  xfce4 \
  xfce4-goodies \
  xorg \
  dbus-x11 \
  lightdm \
  flatpak \
  locales

# --- FIX LOCALE ---
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# --- CREATE USER ---
if ! id "$WORK_USER" &>/dev/null; then
  sudo adduser --disabled-password --gecos "" "$WORK_USER"
  echo "$WORK_USER:$WORK_PASSWORD" | sudo chpasswd
  sudo usermod -aG sudo "$WORK_USER"
fi

# --- PARSEC (FLATPAK) ---
if ! command -v parsec &>/dev/null; then
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  sudo flatpak install -y flathub com.parsec.Par
fi

# --- SET XFCE FOR USER ---
sudo -u "$WORK_USER" bash <<EOT
mkdir -p ~/.config
echo "exec startxfce4 &" > ~/.xinitrc
EOT

# --- AUTOLOGIN ---
sudo mkdir -p /etc/lightdm/lightdm.conf.d
sudo tee /etc/lightdm/lightdm.conf.d/50-autologin.conf >/dev/null <<EOT
[Seat:*]
autologin-user=$WORK_USER
autologin-session=xfce
EOT

echo "=== Done. Reboot recommended ==="
