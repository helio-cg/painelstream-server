#!/bin/bash
# Verificar se é root
if [ "x$(id -u)" != 'x0' ]; then
	echo 'Error: this script can only be executed by root'
	exit 1
fi

# Detect OS
if [ -e "/etc/os-release" ] && [ ! -e "/etc/redhat-release" ]; then
	type=$(grep "^ID=" /etc/os-release | cut -f 2 -d '=')
    if [ "$type" = "debian" ]; then
		release=$(cat /etc/debian_version | grep -o "[0-9]\{1,2\}" | head -n1)
		VERSION='debian'
	else
		type="NoSupport"
	fi
else
	type="NoSupport"
fi

no_support_message() {
	echo "****************************************************"
	echo "Your operating system (OS) is not supported by"
	echo "PainelStream. Officially supported releases:"
	echo "****************************************************"
	echo "  Debian 12, 13"
	echo ""
	exit 1
}

if [ "$type" = "NoSupport" ]; then
	no_support_message
fi

# Atualiza e instala pacotes
apt update && apt upgrade -y
apt install git rsync ca-certificates -y

cd /usr/local && git clone git@github.com:helio-cg/painelstream-server.git painelstream

cd /usr/local/painelstream
sh ./install-icecast.sh
sh ./install-quota.sh