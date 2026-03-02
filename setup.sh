#!/bin/bash


# Atualiza e instala pacotes
apt update -y
apt upgrade -y
apt install git rsync ca-certificates quota -y

# Install caddy proxy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.sh' | sudo bash
sudo apt install -y caddy

DOMAIN="14.stmip.net"
ROOT_PATH="/usr/local/painelstream"

sed -e "s|{{DOMAIN}}|$DOMAIN|g" \
    -e "s|{{ROOT_PATH}}|$ROOT_PATH|g" \
    /usr/local/painelstream/templates/caddy.tpl \
    | sudo tee -a /etc/caddy/Caddyfile > /dev/null

sudo systemctl enable --now caddy
sudo systemctl restart caddy

# Habilitando quota
sudo cp /etc/fstab /etc/fstab.bak.$(date +%F-%H%M%S) && sudo sed -i -E '/errors=remount-ro/ {/usrquota/! s/errors=remount-ro/errors=remount-ro,usrquota,grpquota/}' /etc/fstab
sudo mount -o remount /
sudo tune2fs -O quota /dev/sda1
sudo quotacheck -cum / # Esse comando deve se executado caso a qouta não seja ativada
sudo quotaon -v /

# Copia arquivos para base
mkdir /usr/local/painelstream
git clone https://github.com/helio-cg/painelstream-server.git /usr/local/painelstream



cd /usr/local/painelstream
sh ./install-icecast.sh
sh /usr/local/painelstream/install-server.sh