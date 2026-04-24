#!/bin/bash

# Node.js (versão LTS)
sudo apt update
sudo apt install -y curl

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Redis
sudo apt install -y redis-server

# iniciar serviços
sudo systemctl enable redis
sudo systemctl start redis

sudo systemctl status redis
redis-cli ping
# deve responder: PONG

cd /usr/local/painelstream/src/sftpgo-proxy
npm install

# praticar, pode usar o PM2 para manter o proxy rodando em background
sudo npm install -g pm2
pm2 start server.js --name sftpgo-proxy
pm2 save
pm2 startup