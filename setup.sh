#!/bin/bash

BASE_DIR='/usr/local/painelstream'

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
apt install git rsync ca-certificates libxml2-utils ufw python3-mutagen -y
# Codec AAC, MP3 e OPUS
sudo apt install libfdk-aac-dev fdkaac libmp3lame-dev lame libopus0 libopusfile0 libogg0 opus-tools -y
# Instalação do Icecast2
sudo DEBIAN_FRONTEND=noninteractive \
apt install -y icecast2 >/dev/null 2>&1
# Instalação do Liquidsoap
sudo apt install liquidsoap -y
# Verifica se foi instalado
icecast2 -v
liquidsoap --version

# ==============================
# Habilita Firwall
# ==============================
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 7998/tcp
#sudo ufw allow 2086/tcp # Porta de administração do MinIO
#sudo ufw allow 2087/tcp # Porta de administração do MinIO
sudo ufw --force enable
sudo ufw reload
# Ver estatus e portas
# sudo ufw status verbose

# Configura proxy reverso com Nginx
$BASE_DIR/setup/nginx-install.sh "$DOMAIN"

# Instalação do Docker e Docker Compose
$BASE_DIR/setup/docker.sh

# Instalação do MinIO para gerenciamento de arquivos
$BASE_DIR/setup/file-manager.sh "$DOMAIN"

# Configuração de quota para limitar espaço em disco
$BASE_DIR/setup/quota.sh "$MOUNT"

# Copia arquivos para base
mkdir /usr/local/painelstream
git clone https://github.com/helio-cg/painelstream-server.git /usr/local/painelstream

# Atualiza permissão arquivos do sistema
chmod 600 /usr/local/painelstream/func/main.sh
chown root:root /usr/local/painelstream/func/main.sh

# ==============================
# Atualiza base xml do Icecast
# ==============================
sudo cp -f /usr/local/painelstream/templates/icecast-base.xml /etc/icecast2/icecast.xml

# ==============================
# Configura acesso SFTP
# ==============================
groupadd radiosftp
getent group radiosftp

# Arquivo de configuralçao do grupo sftp
cat > /etc/ssh/sshd_config.d/radiosftp.conf <<EOF
Match Group radiosftp
    ChrootDirectory /home/%u
    ForceCommand internal-sftp -d /ftp/pastas
    AllowTcpForwarding no
    X11Forwarding no
EOF

systemctl restart ssh

echo "Instalação concluida"
echo "Desative usuário root e acesso ssh com senha"