# Instalar
rsync --progress -e 'ssh -p'22 -avz --recursive --rsync-path="sudo rsync" --exclude='.git' /home/helio/Projetos/painelstream-server/ root@46.225.3.15:/tmp/
cd /tmp
sh ./install

rsync --progress -e 'ssh -p'22 -avz --recursive --rsync-path="sudo rsync" --exclude='.git' /home/helio/Projetos/painelstream-server/ root@46.225.3.15:/usr/local/painelstream-server/

/usr/local/painelstream-server/bin/create.sh