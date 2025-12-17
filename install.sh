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
  locales \
  tigervnc-standalone-server \
  tigervnc-scraping-server
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
# --- SET XFCE FOR USER ---
sudo -u "$WORK_USER" bash <<EOT
mkdir -p ~/.config
echo "exec startxfce4 &" > ~/.xinitrc
EOT
# --- VNC SETUP ---
sudo -u "$WORK_USER" bash <<EOT
mkdir -p ~/.vnc
echo "$VNC_PASSWORD" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd
EOT
# --- VNC AUTOSTART (x0vncserver) ---
sudo tee /etc/systemd/system/x0vncserver.service >/dev/null <<EOT
[Unit]
Description=x0vncserver for sharing existing X display
After=lightdm.service
Requires=lightdm.service

[Service]
Type=simple
User=$WORK_USER
Environment=DISPLAY=:0
ExecStart=/usr/bin/x0vncserver -display :0 -passwordfile /home/$WORK_USER/.vnc/passwd -rfbport 5900 -fg -localhost no
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOT
sudo systemctl daemon-reload
sudo systemctl enable x0vncserver.service
# --- RUSTDESK INSTALL ---
wget -O /tmp/rustdesk.deb https://github.com/rustdesk/rustdesk/releases/download/1.4.4/rustdesk-1.4.4-x86_64.deb
sudo apt install -y /tmp/rustdesk.deb
rm /tmp/rustdesk.deb
# --- RUSTDESK SERVICE & PASSWORD ---
sudo rustdesk --install-service
sudo rustdesk --password "$RUSTDESK_PASSWORD"
# --- RUSTDESK AUTOSTART ---
sudo -u "$WORK_USER" bash <<EOT
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/rustdesk.desktop <<EOF
[Desktop Entry]
Type=Application
Name=RustDesk
Exec=rustdesk
X-GNOME-Autostart-enabled=true
EOF
EOT
# --- AUTOLOGIN ---
sudo mkdir -p /etc/lightdm/lightdm.conf.d
sudo tee /etc/lightdm/lightdm.conf.d/50-autologin.conf >/dev/null <<EOT
[Seat:*]
autologin-user=$WORK_USER
autologin-session=xfce
EOT
echo "=== Done. Reboot recommended ==="
echo "After reboot:"
echo "  - VNC: IP:5900 (password from VNC_PASSWORD)"
echo "  - RustDesk: run 'rustdesk --get-id' to get ID, password from RUSTDESK_PASSWORD"
