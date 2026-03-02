#!/bin/bash


# Atualiza e instala pacotes
apt update && apt upgrade -y
apt install git rsync ca-certificates -y

# Install caddy proxy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.sh' | sudo bash
sudo apt install -y caddy

sudo sed -i '$ a \
14.stmip.net {\
    handle_path / {
        root * /usr/local/painelstream
        file_server
    }

    # Bloquear acesso a páginas sensíveis\
    @admin path /admin* / /status.xsl\
    respond @admin 403\

    reverse_proxy / 127.0.0.1:8000 {\
        header_up X-Forwarded-For {remote_host}\
    }\
}' /etc/caddy/Caddyfile

sudo systemctl enable --now caddy
sudo systemctl restart caddy

# Copia arquivos para base
mkdir /usr/local/painelstream
git clone https://github.com/helio-cg/painelstream-server.git /usr/local/painelstream

cd /usr/local/painelstream
sh ./install-quota.sh
sh ./install-icecast.sh
sh /usr/local/painelstream/install-server.sh