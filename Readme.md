# Ciar usuário no servidor
adduser helio
mkdir /home/helio/.ssh

# Execute local (essa chave deve está no servidor do painel para se conectr com servidor stream)
ssh-copy-id -i ~/.ssh/id_ed25519.pub helio@IP_DO_SERVIDOR_STREAM

# Permissões de autorização, adicione antes da chave
nano /home/helio/.ssh/authorized_keys
command="/usr/local/painelstream/runner.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ...

# Instalar

wget https://raw.githubusercontent.com/helio-cg/painelstream-server/refs/heads/main/setup.sh
chmod +x setup.sh
./setup.sh


# Comandos para teste em desenvolvimento
rsync --progress -e 'ssh -p'22 -avz --recursive --rsync-path="sudo rsync" --exclude='.git' /home/helio/Projetos/painelstream-server/ root@14.stmip.net:/usr/local/painelstream/

/usr/local/painelstream-server/bin/create.sh