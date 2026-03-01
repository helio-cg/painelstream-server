#!/bin/sh

# Instalar pacotes
#apt install quota -y

# Atualiza permissão arquivos do sistema
chmod 600 /usr/local/painelstream-server/func/main.sh
chown root:root /usr/local/painelstream-server/func/main.sh

# Cria o grupo de acesso sftp
groupadd radiosftp
getent group radiosftp

# Arquivo de configuralçao do grupo sftp
cat > /etc/ssh/sshd_config.d/radiosftp.conf <<EOF
Subsystem sftp internal-sftp

Match Group radiosftp
    ChrootDirectory /home/%u
    ForceCommand internal-sftp -d /autodj
    AllowTcpForwarding no
    X11Forwarding no
EOF

systemctl restart ssh