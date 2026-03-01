# Instalar

wget https://github.com/helio-cg/painelstream-server/blob/main/setup.sh
chmod +x setup.sh
./setup.sh


# Comandos para teste em desenvolvimento
rsync --progress -e 'ssh -p'22 -avz --recursive --rsync-path="sudo rsync" --exclude='.git' /home/helio/Projetos/painelstream-server/ root@46.225.3.15:/usr/local/painelstream-server/

/usr/local/painelstream-server/bin/create.sh