ENV_FILE="/usr/local/painelstream/src/minio/.env"

if [ "$(id -u)" -ne 0 ]; then
    echo "Este script deve ser executado como root."
    exit 1
fi

# Local de armazenamento para o MinIO
if [ ! -d "/storage" ]; then
    sudo mkdir -p /storage
    sudo chown -R $USER:$USER /storage
fi

# Instalação do Docker e Docker Compose
if ! command -v docker &> /dev/null; then
    echo "Docker não encontrado. Instalando Docker..."
   
    sudo apt install -y ca-certificates curl gnupg lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo systemctl start docker
    sudo systemctl enable docker
    sudo systemctl status docker --no-pager   # deve mostrar active (running)

    sudo usermod -aG docker $USER

    docker --version
    docker compose version

    echo "Docker instalado com sucesso."
else
    echo "Docker já está instalado."
fi

# Ative restart automático caso o daemon caia
sudo systemctl enable --now docker
# (Opcional) Configure o Docker para usar menos log (boa prática em produção)
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
sudo systemctl restart docker

# Cli minio
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc
chmod +x mc
sudo mv mc /usr/local/bin/

echo "=== Configurando credenciais do MinIO ==="
# Cria o diretório se não existir
sudo mkdir -p "$(dirname "$ENV_FILE")"

# Gera credenciais fortes (se ainda não existirem)
if [ ! -f "$ENV_FILE" ]; then
    echo "Gerando novas credenciais seguras..."

    # Gera senha forte de 32 caracteres (pode mudar para 24 ou 40)
    MINIO_ROOT_USER="minioadmin"  # ou o que você preferir
    MINIO_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 32)

    # Cria o arquivo com as variáveis
    sudo tee "$ENV_FILE" > /dev/null <<EOF
# Credenciais MinIO - Gerado automaticamente em $(date)
MINIO_ROOT_USER=${MINIO_ROOT_USER}
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}

# Outras variáveis que você usar no MinIO (adicione aqui)
# MINIO_DOMAIN=...
# MINIO_CONSOLE_ADDRESS=":9001"
EOF

    # Permissões restritas (muito importante!)
    sudo chmod 600 "$ENV_FILE"
    echo "✅ Arquivo ${ENV_FILE} criado com credenciais novas."
    echo "   MINIO_ROOT_USER=${MINIO_ROOT_USER}"
    echo "   MINIO_ROOT_PASSWORD= (gerada automaticamente - guarde em local seguro!)"
else
    echo "✅ Arquivo ${ENV_FILE} já existe. Usando credenciais existentes."
fi

# Carrega as variáveis de forma segura
set -a
source "$ENV_FILE"
set +a

# Verificação básica
if [ -z "${MINIO_ROOT_PASSWORD:-}" ]; then
    echo "❌ Erro: MINIO_ROOT_PASSWORD não foi carregada!"
    exit 1
fi
echo "✅ Credenciais carregadas com sucesso."

chmod 600 /usr/local/painelstream/src/minio/.env 2>/dev/null || true

# Agora sobe o compose usando o arquivo de ambiente
echo "=== Iniciando serviços com Docker Compose ==="

docker compose -f /usr/local/painelstream/src/minio/docker-compose.yml \
  --env-file "$ENV_FILE" \
  up -d --build

if [ $? -ne 0 ]; then
    echo "❌ Erro ao iniciar os serviços com Docker Compose."
    exit 1
fi

echo "Configurando alias do MinIO..."
mc alias set local http://localhost:2086 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

echo "Alias configurado com sucesso!"
mc alias list local

mkdir -p /etc/nginx/sites-available/14.stmip.net.d/
sudo nano /etc/nginx/sites-available/14.stmip.net.d/node-app.conf

# =============================================
# NODE APP - Proxy para aplicação Node.js
# Acessível em: https://14.stmip.net/app/
# =============================================

location /app/ {
    proxy_pass http://node_app:3000/;           # Barra final é importante!

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # WebSocket support
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    # Timeouts
    proxy_read_timeout 300;
    proxy_send_timeout 300;

    # Tamanho máximo de upload
    client_max_body_size 50M;
}

# Redireciona /app (sem barra) para /app/
location = /app {
    return 301 /app/;
}

sudo nano /etc/nginx/sites-available/14.stmip.net.d/minio.conf
# =============================================
# MINIO - Proxy para MinIO Console / API
# =============================================

# Console MinIO (Interface Web)
location /storage/ {
    proxy_pass http://minio:9001/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_read_timeout 300;
}

# API S3 (se precisar expor publicamente - use com cuidado)
# location /minio/ {
#     proxy_pass http://minio:9000/;
#     proxy_set_header Host $host;
#     proxy_set_header X-Real-IP $remote_addr;
#     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#     proxy_set_header X-Forwarded-Proto $scheme;
# }

# Testa a configuração
sudo nginx -t

# Recarrega o Nginx
sudo systemctl reload nginx