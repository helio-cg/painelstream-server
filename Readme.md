# Ciar usuário no servidor
adduser helio
mkdir /home/helio/.ssh
chmod 700 /home/helio/.ssh
nano /home/helio/.ssh/authorized_keys

ssh-copy-id -i ~/.ssh/stream_key.pub helio@IP_DO_SERVIDOR_STREAM
Cole chave publica que vem do helio em: authorized_keys

chmod 600 /home/helio/.ssh/authorized_keys
chown -R helio:helio /home/helio/.ssh

# Instalar

wget https://raw.githubusercontent.com/helio-cg/painelstream-server/refs/heads/main/setup.sh
chmod +x setup.sh
./setup.sh


# Comandos para teste em desenvolvimento
rsync --progress -e 'ssh -p'22 -avz --recursive --rsync-path="sudo rsync" --exclude='.git' /home/helio/Projetos/painelstream-server/ root@14.stmip.net:/usr/local/painelstream/

/usr/local/painelstream-server/bin/create.sh