#!/bin/sh
# Verificar se é root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script precisa ser executado como root."
    exit 1
fi

# Verificar se é Debian
if [ ! -f /etc/os-release ]; then
    echo "❌ Não foi possível identificar o sistema."
    exit 1
fi

. /etc/os-release

if [ "$ID" != "debian" ]; then
    echo "❌ Este script só funciona em Debian."
    exit 1
fi

# Verificar versão Debian 13+
if [ "$VERSION_ID" -lt 13 ]; then
    echo "❌ É necessário Debian 13 ou superior."
    exit 1
fi

apt update && apt upgrade -y
apt install git rsync -y

cd /usr/local
git clone git@github.com:helio-cg/painelstream-server.git painelstream

cd /usr/local/painelstream
sh ./install-icecast.sh
sh ./install-quota.sh