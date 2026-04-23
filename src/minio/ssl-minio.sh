#!/bin/bash

# Esse sript não funciona bem
# vou quere pegar dele apeans a parte de analisa 
# se certificado foi atualizado e atualizar os links simbolicos para o minio


set -euo pipefail

DOMAIN="${1:-}"
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
TARGET_DIR="/storage/minio-certs"
COMPOSE_FILE="/usr/local/painelstream/src/minio/docker-compose.yml"
SERVICE_NAME="minio"
LOG_FILE="/var/log/minio-cert-renew.log"
STATE_FILE="/var/lib/minio-cert-last-fingerprint"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$STATE_FILE")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

fail() {
  log "ERRO: $1"
  exit 1
}

log "=== Iniciando deploy de certificado para MinIO ==="

# 🔍 Verificar arquivos
FULLCHAIN="$CERT_DIR/fullchain.pem"
PRIVKEY="$CERT_DIR/privkey.pem"

[[ -f "$FULLCHAIN" ]] || fail "fullchain.pem não encontrado"
[[ -f "$PRIVKEY" ]] || fail "privkey.pem não encontrado"

# 🔐 Validar certificado
if ! openssl x509 -in "$FULLCHAIN" -noout -text > /dev/null 2>&1; then
  fail "Certificado inválido"
fi

# 🔑 Fingerprint atual
NEW_FP=$(openssl x509 -noout -fingerprint -sha256 -in "$FULLCHAIN" | cut -d= -f2)

# 📌 Verificar se mudou
if [[ -f "$STATE_FILE" ]]; then
  OLD_FP=$(cat "$STATE_FILE")
else
  OLD_FP=""
fi

if [[ "$NEW_FP" == "$OLD_FP" ]]; then
  log "Certificado não mudou. Nenhuma ação necessária."
  exit 0
fi

log "Novo certificado detectado"

# 💾 Backup anterior
BACKUP_DIR="$TARGET_DIR/backup_$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [[ -f "$TARGET_DIR/public.crt" ]]; then
  cp -L "$TARGET_DIR/public.crt" "$BACKUP_DIR/public.crt" || true
fi

if [[ -f "$TARGET_DIR/private.key" ]]; then
  cp -L "$TARGET_DIR/private.key" "$BACKUP_DIR/private.key" || true
fi

log "Backup salvo em $BACKUP_DIR"

# 🔗 Atualizar symlinks
#ln -sf "$FULLCHAIN" "$TARGET_DIR/public.crt"
#ln -sf "$PRIVKEY" "$TARGET_DIR/private.key"

chmod 600 "$TARGET_DIR/private.key"
chmod 644 "$TARGET_DIR/public.crt"

log "Symlinks atualizados"

# 🔄 Reiniciar serviço
log "Reiniciando container MinIO..."

if docker compose -f "$COMPOSE_FILE" restart "$SERVICE_NAME"; then
  log "MinIO reiniciado com sucesso"
else
  log "Falha ao reiniciar MinIO — iniciando rollback"

  # 🔙 rollback
  if [[ -f "$BACKUP_DIR/public.crt" && -f "$BACKUP_DIR/private.key" ]]; then
    cp "$BACKUP_DIR/public.crt" "$TARGET_DIR/public.crt"
    cp "$BACKUP_DIR/private.key" "$TARGET_DIR/private.key"

    docker compose -f "$COMPOSE_FILE" restart "$SERVICE_NAME" || true

    fail "Rollback aplicado"
  else
    fail "Rollback impossível — backup inexistente"
  fi
fi

# 💾 Salvar fingerprint
echo "$NEW_FP" > "$STATE_FILE"

log "Fingerprint atualizado"
log "=== Deploy finalizado com sucesso ==="