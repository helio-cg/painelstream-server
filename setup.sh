#!/bin/bash

DOMAIN=$1

# Atualiza e instala pacotes
apt update -y
apt upgrade -y
apt install git rsync ca-certificates quota libxml2-utils -y

# Install caddy proxy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.sh' | sudo bash
sudo apt install -y caddy

# Configura Caddy
sudo /usr/local/painelstream/src/caddy.sh $DOMAIN
sudo systemctl enable --now caddy

# Habilitando quota
sudo cp /etc/fstab /etc/fstab.bak.$(date +%F-%H%M%S) && sudo sed -i -E '/errors=remount-ro/ {/usrquota/! s/errors=remount-ro/errors=remount-ro,usrquota,grpquota/}' /etc/fstab
sudo mount -o remount /
sudo tune2fs -O quota /dev/sda1
sudo quotacheck -cum / # Esse comando deve se executado caso a qouta não seja ativada
sudo quotaon -v /

# Copia arquivos para base
mkdir /usr/local/painelstream
git clone https://github.com/helio-cg/painelstream-server.git /usr/local/painelstream

BIN_PATH="/usr/local/painelstream/bin"
BASHRC="$HOME/.bashrc"

echo "Configurando PATH em $BASHRC ..."

# Verifica se já existe
if ! grep -q "$BIN_PATH" "$BASHRC"; then
    echo "" >> "$BASHRC"
    echo "# PainelStream PATH" >> "$BASHRC"
    echo "export PATH=\$PATH:$BIN_PATH" >> "$BASHRC"
    echo "PATH adicionado com sucesso!"
else
    echo "PATH já está configurado."
fi
echo "Execute: source ~/.bashrc ou abra novo terminal."

cd /usr/local/painelstream
sh ./install-icecast.sh
sh /usr/local/painelstream/install-server.sh