#!/bin/bash

# Função para instalar o Docker
install_docker() {
    echo "Instalando Docker..."
    apt update
    apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    echo "Docker instalado com sucesso."
}

# Função para instalar o K3s agent e conectar ao servidor principal
install_k3s_agent() {
    SERVER_URL=$1
    TOKEN=$2

    if [ -z "$SERVER_URL" ] || [ -z "$TOKEN" ]; then
        echo "Para adicionar um agent, forneça o URL do servidor K3s e o token."
        exit 1
    fi

    echo "Instalando K3s agent..."
    curl -sfL https://get.k3s.io | K3S_URL="https://$SERVER_URL:6443" K3S_TOKEN="$TOKEN" sh -
    echo "K3s agent instalado e conectado ao servidor."
}

# Função principal
main() {
    if [ "$#" -ne 2 ]; then
        echo "Uso: $0 <IP_DO_SERVIDOR> <TOKEN>"
        exit 1
    fi

    SERVER_URL=$1
    TOKEN=$2

    install_docker
    install_k3s_agent $SERVER_URL $TOKEN
}

# Executa o script principal
main "$@"
