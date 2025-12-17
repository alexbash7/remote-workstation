ssh@ip

sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget

cd /root
git clone https://github.com/alexbash7/remote-workstation.git

chmod +x install.sh
./install.sh

