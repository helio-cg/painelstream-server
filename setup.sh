#!/bin/bash

# ==============================
# VERIFICA SE É ROOT
# ==============================
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script precisa ser executado como root."
    exit 1
fi

# ==============================
# Configuração de quota
# ==============================
echo "Onde deseja configurar a quota?"
echo "1) /"
echo "2) /home"

read -p "Escolha uma opção [1-2]: " OPTION

if [ "$OPTION" = "2" ]; then
    MOUNT="/home"
else
    MOUNT="/"
fi

echo "Mount escolhido: $MOUNT"

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
apt install git rsync ca-certificates quota libxml2-utils ufw python3-mutagen -y
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
# Criar usuário sudo
# ==============================
# Cria usuário sem senha (disabled password)
#sudo useradd -m -s /bin/bash "helio"
# Adiciona ao grupo sudo (Ubuntu/Debian) ou wheel (CentOS/RHEL)
#sudo usermod -aG sudo "helio"  # ou wheel, dependendo da distro
#echo 'helio ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers.d/helio-nopasswd
# Recomenda desativar login com senha e usuário root

# ==============================
# Habilita Firwall
# ==============================
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 7998/tcp
sudo ufw --force enable
# Ver estatus e portas
# sudo ufw status verbose

# Install caddy proxy
#sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
#curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.sh' | sudo bash
#sudo apt install -y caddy
sudo apt install -y nginx
sudo systemctl enable --now nginx

# ==============================
# Habilita Quota
# ==============================
sudo cp /etc/fstab /etc/fstab.bak.$(date +%F-%H%M%S) && sudo sed -i -E '/errors=remount-ro/ {/usrquota/! s/errors=remount-ro/errors=remount-ro,usrquota,grpquota/}' /etc/fstab
#MOUNT="/"
DISK=$(findmnt -n -o SOURCE --target "$MOUNT")
sudo tune2fs -O quota "$DISK"
# ⚠ precisa reiniciar após tune2fs se quota ainda não estava habilitado
# sudo reboot
sudo tee /etc/systemd/system/firstboot-quota.service > /dev/null <<EOF
[Unit]
Description=First Boot Quota Initialization
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/firstboot-quota.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

sudo tee /usr/local/bin/firstboot-quota.sh > /dev/null <<EOF
#!/bin/bash

MOUNT="/"

echo "Iniciando configuração de quota..."

quotacheck -cum "\$MOUNT"
mount -o remount "\$MOUNT"
quotaon "\$MOUNT"
repquota -a

systemctl disable firstboot-quota.service
rm -f /etc/systemd/system/firstboot-quota.service
rm -f /usr/local/bin/firstboot-quota.sh

echo "Configuração concluída."

# Inicia o serviço Icecast
sudo systemctl enable icecast2
sudo systemctl start icecast2
#sudo systemctl reload icecast2

EOF

echo "Cria caminho para executar script de qualquer lugar"
echo 'export PATH=$PATH:/usr/local/painelstream/bin' | sudo tee /etc/profile.d/painelstream.sh > /dev/null

sudo chmod +x /usr/local/bin/firstboot-quota.sh
sudo systemctl enable firstboot-quota.service
#quotacheck -cum "$MOUNT"
#sudo mount -o remount "$MOUNT"
#sudo repquota -a # Ver cota de usuários

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
# Configura proxy
# ==============================
#sudo /usr/local/painelstream/src/caddy.sh $DOMAIN
#sudo systemctl enable --now caddy

# ==============================
# Configura acesso SFTP
# ==============================
groupadd radiosftp
getent group radiosftp

# Arquivo de configuralçao do grupo sftp
#cat > /etc/ssh/sshd_config.d/radiosftp.conf <<EOF
#Subsystem sftp internal-sftp

#Match Group radiosftp
#    ChrootDirectory /home/%u
#    ForceCommand internal-sftp -d /ftp/pastas
#    AllowTcpForwarding no
#    X11Forwarding no
#EOF

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