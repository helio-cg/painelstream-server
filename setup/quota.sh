#!/bin/bash

if [ -z "$MOUNT" ]; then
    echo "Onde deseja configurar a quota?"
    echo "1) /"
    echo "2) /home"

    read -p "Escolha uma opção [1-2]: " OPTION

    if [ "$OPTION" = "2" ]; then
        MOUNT="/home"
    else
        MOUNT="/"
    fi
else
    echo "Mount escolhido: $MOUNT"
fi

apt install quota -y

# ==============================
# Habilita Quota
# ==============================
sudo cp /etc/fstab /etc/fstab.bak.$(date +%F-%H%M%S) && sudo sed -i -E '/errors=remount-ro/ {/usrquota/! s/errors=remount-ro/errors=remount-ro,usrquota,grpquota/}' /etc/fstab
#MOUNT="/"
DISK=$(findmnt -n -o SOURCE --target "$MOUNT")
sudo tune2fs -O quota "$DISK"
# ⚠ precisa reiniciar após tune2fs se quota ainda não estava habilitado
# sudo reboot
sudo tee /etc/systemd/system/firstboot-quota.service > /dev/null <<EOF
[Unit]
Description=First Boot Quota Initialization
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/firstboot-quota.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

sudo tee /usr/local/bin/firstboot-quota.sh > /dev/null <<EOF
#!/bin/bash

MOUNT="/"

echo "Iniciando configuração de quota..."

quotacheck -cum "\$MOUNT"
mount -o remount "\$MOUNT"
quotaon "\$MOUNT"
repquota -a

systemctl disable firstboot-quota.service
rm -f /etc/systemd/system/firstboot-quota.service
rm -f /usr/local/bin/firstboot-quota.sh

echo "Configuração concluída."

# Inicia o serviço Icecast
sudo systemctl enable icecast2
sudo systemctl start icecast2
#sudo systemctl reload icecast2

EOF

echo "Cria caminho para executar script de qualquer lugar"
echo 'export PATH=$PATH:/usr/local/painelstream/bin' | sudo tee /etc/profile.d/painelstream.sh > /dev/null

sudo chmod +x /usr/local/bin/firstboot-quota.sh
sudo systemctl enable firstboot-quota.service
#quotacheck -cum "$MOUNT"
#sudo mount -o remount "$MOUNT"
#sudo repquota -a # Ver cota de usuários