#!/bin/bash

BASE_DIR='/usr/local/painelstream'
ENV_FILE="$BASE_DIR/src/sftp/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Criando .env..."

  POSTGRES_USER="sftpgo"
  POSTGRES_PASSWORD=$(openssl rand -base64 12)
  POSTGRES_DB="sftpgo"

  cat <<EOF > $ENV_FILE
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=$POSTGRES_DB
EOF

  echo ".env criado com sucesso!"
else
  echo ".env já existe"
fi

docker compose -f $BASE_DIR/src/sftp/docker-compose.yml up -d