# Instalar

wget https://raw.githubusercontent.com/helio-cg/painelstream-server/refs/heads/main/setup.sh
chmod +x setup.sh
./setup.sh


# Comandos para teste em desenvolvimento
rsync --progress -e 'ssh -p'22 -avz --recursive --rsync-path="sudo rsync" --exclude='.git' /home/helio/Projetos/painelstream-server/ root@14.stmip.net:/usr/local/painelstream/

/usr/local/painelstream-server/bin/create.sh