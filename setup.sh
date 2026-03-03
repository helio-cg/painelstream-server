#!/bin/bash

# ==============================
# VERIFICA SE É ROOT
# ==============================
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script precisa ser executado como root."
    exit 1
fi

# ==============================
# DOMÍNIO (ARGUMENTO OU INPUT)
# ==============================
DOMAIN="${1:-}"

while true; do
    if [ -z "$DOMAIN" ]; then
        read -r -p "🌐 Digite o domínio (ex: radio.exemplo.com): " DOMAIN
    fi

    # Validação básica de domínio
    if [[ "$DOMAIN" =~ ^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$ ]]; then
        break
    else
        echo "❌ Domínio inválido. Tente novamente."
        DOMAIN=""
    fi
done

echo ""
echo "Domínio informado: $DOMAIN"
echo ""

# ==============================
# CONFIRMAÇÃO
# ==============================
read -p "Deseja continuar com esse domínio? (s/n): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Ss]$ ]]; then
    echo "❌ Operação cancelada."
    exit 1
fi

echo ""
echo "✅ Prosseguindo com configuração para $DOMAIN..."

# ==============================
# Atualizar sistema e instalar pacotes
# ==============================
apt update -y
apt upgrade -y
apt install git rsync ca-certificates quota libxml2-utils -y
# Codec AAC, MP3 e OPUS
sudo apt install libfdk-aac-dev fdkaac libmp3lame-dev lame libopus0 libopusfile0 libogg0 opus-tools -y
# Instalação do Icecast2
sudo apt install icecast2 -y
# Instalação do Liquidsoap
sudo apt install liquidsoap -y

# Verifica se foi instalado
icecast2 -v
liquidsoap --version

rm -rf /etc/icecast2/icecast.xml
cp /usr/local/painelstream/templates/icecast-base.xml /etc/icecast2/icecast.xml

sleep 1

# Iniciaa o serviço Icecast
sudo systemctl start icecast2
sudo systemctl reload icecast2

# Install caddy proxy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.sh' | sudo bash
sudo apt install -y caddy

# Habilitando quota
sudo cp /etc/fstab /etc/fstab.bak.$(date +%F-%H%M%S) && sudo sed -i -E '/errors=remount-ro/ {/usrquota/! s/errors=remount-ro/errors=remount-ro,usrquota,grpquota/}' /etc/fstab
MOUNT="/"
DISK=$(findmnt -n -o SOURCE --target "$MOUNT")
sudo tune2fs -O quota "$DISK"
# ⚠ precisa reiniciar após tune2fs se quota ainda não estava habilitado
# sudo reboot
quotacheck -cum "$MOUNT"
sudo mount -o remount "$MOUNT"
sudo repquota -a # Ver cota de usuários

# Copia arquivos para base
mkdir /usr/local/painelstream
git clone https://github.com/helio-cg/painelstream-server.git /usr/local/painelstream

# Atualiza permissão arquivos do sistema
chmod 600 /usr/local/painelstream/func/main.sh
chown root:root /usr/local/painelstream/func/main.sh

# ==============================
# Configura proxy
# ==============================
sudo /usr/local/painelstream/src/caddy.sh $DOMAIN
sudo systemctl enable --now caddy

# ==============================
# Configura acesso SFTP
# ==============================
groupadd radiosftp
getent group radiosftp

# Arquivo de configuralçao do grupo sftp
cat > /etc/ssh/sshd_config.d/radiosftp.conf <<EOF
Subsystem sftp internal-sftp

Match Group radiosftp
    ChrootDirectory /home/%u
    ForceCommand internal-sftp -d /autodj
    AllowTcpForwarding no
    X11Forwarding no
EOF

systemctl restart ssh