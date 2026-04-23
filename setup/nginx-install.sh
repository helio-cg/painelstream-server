#!/bin/bash

DOMAIN="${1:-}"

sudo apt install -y nginx
sudo systemctl enable --now nginx
sudo systemctl status nginx

sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root /usr/local/painelstream/public;
    index index.html index.htm index.nginx-debian.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    include /etc/nginx/includes/radios/*.conf;
    include /etc/nginx/includes/*.conf;
}

server {
    listen 80;
    server_name storage.$DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:8080;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_read_timeout 300;

        access_log /var/log/nginx/sftp_access.log;
        error_log /var/log/nginx/sftp_error.log;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

mkdir -p /etc/nginx/includes/radios/
chmod 755 /etc/nginx/includes/radios/

# ==============================
# SSL com Let's Encrypt
# ==============================
sudo apt install certbot python3-certbot-nginx -y

echo "=== Gerando SSL para $DOMAIN ==="

sudo certbot --nginx \
  -d "$DOMAIN" \
  -d "storage.$DOMAIN" \
  --non-interactive \
  --agree-tos \
  --email "falecom@elicast.app" \
  --redirect \
  --no-eff-email

if [ $? -eq 0 ]; then
    echo "✅ SSL configurado com sucesso!"
    sudo certbot renew --dry-run
else
    echo "❌ Erro ao configurar SSL"
fi