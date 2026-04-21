#!/bin/bash

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