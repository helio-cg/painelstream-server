#!/bin/bash

DOMAIN=$1
EMAIL="[falecom@elicast.app](mailto:falecom@elicast.app)"

if [ -z "$DOMAIN" ]; then
echo "❌ Uso: ./sftpgo.sh dominio.com"
exit 1
fi

echo "🚀 Instalando dependências..."
apt update
apt install -y curl gnupg nginx certbot python3-certbot-nginx

echo "🔑 Instalando SFTPGo..."
curl -sS https://download.sftpgo.com/apt/gpg.key | 
gpg --dearmor -o /usr/share/keyrings/sftpgo-archive-keyring.gpg

CODENAME=$(lsb_release -c -s)

echo "deb [signed-by=/usr/share/keyrings/sftpgo-archive-keyring.gpg] https://download.sftpgo.com/apt ${CODENAME} main" | 
tee /etc/apt/sources.list.d/sftpgo.list

apt update
apt install -y sftpgo

echo "▶️ Iniciando SFTPGo..."
systemctl enable sftpgo
systemctl start sftpgo

echo "📁 Criando diretórios..."
mkdir -p /data
chmod 755 /data

echo "✅ INSTALAÇÃO CONCLUÍDA"
echo "🌐 Acesse: https://$DOMAIN"
echo "⚙️ Primeiro acesso: criar usuário admin na tela inicial"
