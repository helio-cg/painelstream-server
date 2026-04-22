#!/bin/bash

DOMAIN="${1:-}"
ENV_FILE="/usr/local/painelstream/src/minio/.env"


# Local de armazenamento para o MinIO
if [ ! -d "/storage" ]; then
    sudo mkdir -p /storage
    sudo chown -R $USER:$USER /storage
fi

# Cli minio
curl -L -o mc https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/

# Instalação do Redis para o MinIO
#npm install redis

echo "=== Configurando credenciais do MinIO ==="
# Cria o diretório se não existir
sudo mkdir -p "$(dirname "$ENV_FILE")"

# Gera credenciais fortes (se ainda não existirem)
if [ ! -f "$ENV_FILE" ]; then
    echo "Gerando novas credenciais seguras..."

    # Gera senha forte de 32 caracteres (pode mudar para 24 ou 40)
    MINIO_ROOT_USER="minioadmin"  # ou o que você preferir
    MINIO_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 32)
    MINIO_SERVER_URL="https://$DOMAIN:9000"  # Substitua pelo seu domínio
    MINIO_BROWSER_REDIRECT_URL="https://$DOMAIN:9001"

    # Cria o arquivo com as variáveis
    sudo tee "$ENV_FILE" > /dev/null <<EOF
# Credenciais MinIO - Gerado automaticamente em $(date)
MINIO_ROOT_USER=${MINIO_ROOT_USER}
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}
MINIO_SERVER_URL=${MINIO_SERVER_URL}
MINIO_BROWSER_REDIRECT_URL=${MINIO_BROWSER_REDIRECT_URL}
REDIS_HOST=redis
REDIS_PORT=6379
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

echo "⏳ Aguardando MinIO ficar disponível..."

until curl -s http://localhost:9000/minio/health/live > /dev/null; do
  sleep 2
done

echo "✅ MinIO está pronto!"
echo "Configurando alias do MinIO..."
mc alias set local http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"
#mc alias set local https://14.stmip.net:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

echo "Alias configurado com sucesso!"
mc alias list local

# Configura o SSL para o MinIO
#/usr/local/painelstream/src/minio/ssl-minio.sh "$DOMAIN"
#echo "✅ Configuração do MinIO concluída com sucesso!"
# Script de renovação automática dos certificados (exemplo usando certbot) 
#!/bin/bash
#DOMAIN="15.stmip.net"  # Substitua pelo seu domínio
cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /storage/minio-certs/public.crt
cp /etc/letsencrypt/live/$DOMAIN/privkey.pem   /storage/minio-certs/private.key
chmod 600 /storage/minio-certs/private.key
chmod 644 /storage/minio-certs/public.crt
#docker compose -f /caminho/para/seu/docker-compose.yml restart minio