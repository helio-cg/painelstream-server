#!/bin/bash

DOMAIN="${1:-}"

sudo apt install -y nginx
sudo systemctl enable --now nginx
sudo systemctl status nginx   # deve mostrar "active (running)"

sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root /usr/local/painelstream/public;
    index index.html index.htm index.nginx-debian.html;

    location = /app {
        return 301 /app/;
    }

    location ^~ /app/ {
        proxy_pass http://127.0.0.1:3000/;
        include proxy_params;
    }

    location / {
        try_files \$uri \$uri/ =404;
    }

    include /etc/nginx/includes/radios/*.conf;
    include /etc/nginx/includes/*.conf;
}
EOF

sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

mkdir -p /etc/nginx/includes/radios/
chmod 755 /etc/nginx/includes/radios/

# ==============================
# Instalação do Certificado (Let's Encrypt)
# ==============================
sudo apt install certbot python3-certbot-nginx -y
echo "=== Obtendo certificado Let's Encrypt para $DOMAIN ==="

sudo certbot --nginx \
  -d "$DOMAIN" \
  --non-interactive \
  --agree-tos \
  --email "falecom@elicast.app" \
  --redirect \
  --no-eff-email

# Verifica se deu certo
if [ $? -eq 0 ]; then
    echo "✅ Certificado instalado com sucesso!"
    sudo certbot renew --dry-run
else
    echo "❌ Erro ao obter o certificado."
fi