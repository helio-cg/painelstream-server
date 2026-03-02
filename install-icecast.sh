#!/bin/bash

sudo apt update && sudo apt upgrade -y

# Codec AAC
sudo apt install libfdk-aac-dev fdkaac -y

# Codec MP3
sudo apt install libmp3lame-dev lame -y

# Codec Opus
sudo apt install -y libopus0 libopusfile0 libogg0 opus-tools

# Instalação do Icecast2
sudo apt install icecast2 -y

# Instalação do Liquidsoap
sudo apt install liquidsoap -y

icecast2 -v
liquidsoap --version

rm -rf /etc/icecast2/icecast.xml
cp /usr/local/painelstream/templates/icecast-base-xml /etc/icecast2/icecast.xml

systemctl start icecast2
systemctl reload icecast2