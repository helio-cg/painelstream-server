if [ "$(id -u)" -ne 0 ]; then
    echo "Este script deve ser executado como root."
    exit 1
fi

# Local de armazenamento para o MinIO
if [ ! -d "/storage" ]; then
    sudo mkdir -p /storage
    sudo chown -R $USER:$USER /storage
fi

# Cli minio
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc
chmod +x mc
sudo mv mc /usr/local/bin/

# Carrega credenciais de forma segura
if [ -f /usr/local/painelstream/setup/minio-install.env ]; then
    set -a
    source /usr/local/painelstream/setup/minio-install.env
    set +a
else
    echo "Arquivo /usr/local/painelstream/setup/minio-install.env não encontrado!"
    exit 1
fi

chmod 600 /usr/local/painelstream/setup/minio-install.env 2>/dev/null || true

echo "Configurando alias do MinIO..."
mc alias set local http://localhost:2086 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

echo "Alias configurado com sucesso!"
mc alias list local

#mc alias set local http://localhost:2086 admin password123