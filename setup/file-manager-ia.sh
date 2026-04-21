#!/bin/bash
# =============================================
# PainelStream - Script de Instalação
# Docker + MinIO + Nginx Proxy
# =============================================

set -euo pipefail

# ==================== CONFIGURAÇÕES ====================
ENV_FILE="/usr/local/painelstream/src/minio/.env"
DOCKER_COMPOSE_FILE="/usr/local/painelstream/src/minio/docker-compose.yml"
DOMAIN="14.stmip.net"
NGINX_DIR="/etc/nginx/sites-available/${DOMAIN}.d"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verifica se está rodando como root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Erro: Este script deve ser executado como root.${NC}"
    exit 1
fi

echo -e "${GREEN}=== Iniciando instalação do PainelStream ===${NC}"

# ==================== DIRETÓRIOS ====================
echo -e "${YELLOW}→ Criando diretórios necessários...${NC}"
mkdir -p /storage
mkdir -p "$(dirname "$ENV_FILE")"
mkdir -p "$NGINX_DIR"

chown -R $SUDO_USER:$SUDO_USER /storage 2>/dev/null || true

# ==================== INSTALAÇÃO DO DOCKER ====================
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}→ Docker não encontrado. Instalando...${NC}"
    
    apt update
    apt install -y ca-certificates curl gnupg lsb-release

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl enable --now docker
    usermod -aG docker $SUDO_USER

    echo -e "${GREEN}✅ Docker instalado com sucesso.${NC}"
else
    echo -e "${GREEN}✅ Docker já está instalado.${NC}"
fi

# Configuração de logs do Docker (boa prática)
echo -e "${YELLOW}→ Configurando limites de log do Docker...${NC}"
tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
systemctl restart docker

# ==================== INSTALAÇÃO DO MINIO CLIENT (mc) ====================
if ! command -v mc &> /dev/null; then
    echo -e "${YELLOW}→ Instalando MinIO Client (mc)...${NC}"
    curl -s https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc
    chmod +x /usr/local/bin/mc
    echo -e "${GREEN}✅ MinIO Client instalado.${NC}"
fi

# ==================== CONFIGURAÇÃO DE CREDENCIAIS MINIO ====================
echo -e "${YELLOW}→ Configurando credenciais do MinIO...${NC}"

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}→ Gerando novas credenciais seguras...${NC}"
    
    MINIO_ROOT_USER="minioadmin"
    MINIO_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 32)

    tee "$ENV_FILE" > /dev/null <<EOF
# Credenciais MinIO - Gerado automaticamente em $(date)
MINIO_ROOT_USER=${MINIO_ROOT_USER}
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}
EOF

    chmod 600 "$ENV_FILE"
    echo -e "${GREEN}✅ Credenciais geradas e salvas em ${ENV_FILE}${NC}"
    echo -e "   Usuário: ${MINIO_ROOT_USER}"
    echo -e "   Senha  : ${MINIO_ROOT_PASSWORD}  ${RED}(Guarde em local seguro!)${NC}"
else
    echo -e "${GREEN}✅ Usando credenciais existentes.${NC}"
fi

# Carrega variáveis
set -a
source "$ENV_FILE"
set +a

# ==================== INICIANDO DOCKER COMPOSE ====================
echo -e "${YELLOW}→ Iniciando serviços com Docker Compose...${NC}"

if [ -f "$DOCKER_COMPOSE_FILE" ]; then
    docker compose -f "$DOCKER_COMPOSE_FILE" --env-file "$ENV_FILE" up -d --build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Serviços iniciados com sucesso.${NC}"
    else
        echo -e "${RED}❌ Erro ao iniciar os serviços.${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Arquivo docker-compose.yml não encontrado: ${DOCKER_COMPOSE_FILE}${NC}"
    exit 1
fi

# ==================== CONFIGURAÇÃO DO MINIO CLIENT ====================
echo -e "${YELLOW}→ Configurando alias do MinIO...${NC}"
mc alias set local http://localhost:2086 "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" >/dev/null 2>&1 || true
echo -e "${GREEN}✅ Alias 'local' configurado.${NC}"

# ==================== CONFIGURAÇÃO DO NGINX ====================
echo -e "${YELLOW}→ Criando templates Nginx...${NC}"

# Node App
cat > "${NGINX_DIR}/node-app.conf" <<'EOF'
# =============================================
# NODE APP - Proxy para aplicação Node.js
# Acessível em: https://14.stmip.net/app/
# =============================================

location /app/ {
    proxy_pass http://node_app:3000/;   

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    proxy_read_timeout 300;
    proxy_send_timeout 300;
    client_max_body_size 50M;
}

location = /app {
    return 301 /app/;
}
EOF

# MinIO Console
cat > "${NGINX_DIR}/minio.conf" <<'EOF'
# =============================================
# MINIO - Console de Administração
# Acessível em: https://14.stmip.net/storage/
# =============================================

location /storage/ {
    proxy_pass http://minio:9001/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_read_timeout 300;
}
EOF

# ==================== ATIVANDO NGINX ====================
echo -e "${YELLOW}→ Configurando site principal do Nginx...${NC}"

cat > "/etc/nginx/sites-available/${DOMAIN}" <<EOF
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN} www.${DOMAIN};

    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Inclui configurações separadas
    include ${NGINX_DIR}/*.conf;

    location = / {
        return 301 /app/;
    }
}
EOF

ln -sf "/etc/nginx/sites-available/${DOMAIN}" "/etc/nginx/sites-enabled/"

# Teste e recarrega Nginx
if nginx -t; then
    systemctl reload nginx
    echo -e "${GREEN}✅ Nginx configurado e recarregado com sucesso.${NC}"
else
    echo -e "${RED}❌ Erro na configuração do Nginx.${NC}"
    exit 1
fi

echo -e "\n${GREEN}=============================================${NC}"
echo -e "${GREEN}Instalação concluída com sucesso!${NC}"
echo -e "${GREEN}=============================================${NC}"
echo -e "Acesse sua aplicação em: ${YELLOW}https://${DOMAIN}/app/${NC}"
echo -e "Console MinIO em: ${YELLOW}https://${DOMAIN}/storage/${NC}"
echo -e "\n${RED}Lembre-se de rodar o Certbot para gerar o SSL:${NC}"
echo -e "   sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN} --redirect"