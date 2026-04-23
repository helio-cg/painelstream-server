- gerar json de musicas (a de pastas já está ok) 17/04/2026


# Permissões de autorização, adicione antes da chave
nano /home/painelstream/.ssh/authorized_keys
command="/usr/local/painelstream/runner.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ...

# Instalar
cd /tmp
wget https://raw.githubusercontent.com/helio-cg/painelstream-server/refs/heads/main/setup.sh
chmod +x setup.sh
./setup.sh


# Comandos para teste em desenvolvimento
rsync --progress -e 'ssh -p'22 -avz --recursive --rsync-path="sudo rsync" --exclude='.git' /home/helio/GitHub/painelstream-server/ root@15.stmip.net:/usr/local/painelstream/

/usr/local/painelstream-server/bin/create.sh

# DOC: https://docs.sftpgo.com/enterprise/rest-api/#case-a-creating-a-standalone-user-no-group
# SFTPGo endpoint and credentials
ENDPOINT="https://storage.16.stmip.net"
ADMIN_USER="admin"
ADMIN_PASSWORD="1234567"

# Get the JWT Token
TOKEN=$(curl --anyauth -s -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
  "${ENDPOINT}/api/v2/token" | jq -r .access_token)

echo "Token acquired."
echo $TOKEN

# cRIAR USUÁRIO:
USER_PAYLOAD=$(cat <<EOF
{
  "status": 1,
  "username": "testuser_standalone",
  "password": "clear_text_complex_password",
  "permissions": {
    "/": ["*"]
  },
  "filesystem": {
    "provider": 1,
    "s3config": {
      "bucket": "testbucket",
      "region": "eu-central-1",
      "access_key": "myaccesskey",
      "access_secret": {
        "status": "Plain",
        "payload": "myaccesssecret"
      },
      "key_prefix": "users/testuser_standalone/"
    }
  }
}
EOF
)

# Create the user
curl -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${USER_PAYLOAD}" \
  "${ENDPOINT}/api/v2/users"