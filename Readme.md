# Ciar usuário no servidor
adduser painelstream

ssh-copy-id -i ~/.ssh/id_ed25519.pub painelstream@IP_DO_SERVIDOR_STREAM

echo 'painelstream ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers.d/painelstream-nopasswd

ssh painelstream@IP_DO_SERVIDOR_STREAM
ssh-keygen

# Permissões de autorização, adicione antes da chave
nano /home/painelstream/.ssh/authorized_keys
command="/usr/local/painelstream/runner.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ...

# Instalar
cd /tmp
wget https://raw.githubusercontent.com/helio-cg/painelstream-server/refs/heads/main/setup.sh
chmod +x setup.sh
./setup.sh


# Comandos para teste em desenvolvimento
rsync --progress -e 'ssh -p'22 -avz --recursive --rsync-path="sudo rsync" --exclude='.git' /home/helio/GitHub/painelstream-server/ root@14.stmip.net:/usr/local/painelstream/

/usr/local/painelstream-server/bin/create.sh
