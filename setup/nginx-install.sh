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

    location = /app {
        return 301 /app/;
    }

    location ^~ /app/ {
        proxy_pass http://127.0.0.1:3000/;
        include proxy_params;
    }

    # 🔥 SFTPGo (sem conflito)
    location ^~ /storage/ {
        proxy_pass http://127.0.0.1:8080/;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_redirect off;
    }

    location / {
        try_files \$uri \$uri/ =404;
    }

    include /etc/nginx/includes/radios/*.conf;
    include /etc/nginx/includes/*.conf;
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