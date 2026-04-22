- gerar json de musicas (a de pastas já está ok) 17/04/2026


# Permissões de autorização, adicione antes da chave
nano /home/painelstream/.ssh/authorized_keys
command="/usr/local/painelstream/runner.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ...

# Instalar
cd /tmp
wget https://raw.githubusercontent.com/helio-cg/painelstream-server/refs/heads/main/setup.sh
chmod +x setup.sh
./setup.sh


# Comandos para teste em desenvolvimento
rsync --progress -e 'ssh -p'22 -avz --recursive --rsync-path="sudo rsync" --exclude='.git' /home/helio/GitHub/painelstream-server/ root@15.stmip.net:/usr/local/painelstream/

/usr/local/painelstream-server/bin/create.sh
