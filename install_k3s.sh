#!/bin/bash

# Função para instalar Docker
install_docker() {
    echo "Instalando Docker..."
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl start docker
    sudo systemctl enable docker
    echo "Docker instalado com sucesso."
}

# Função para instalar o Portainer
install_portainer() {
    echo "Instalando Portainer..."
    sudo docker volume create portainer_data
    sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
    echo "Portainer instalado com sucesso."
}

# Função para instalar K3s
install_k3s() {
    NODE_TYPE=$1
    ETCD_ENDPOINT=$2
    TOKEN=$3

    if [ "$NODE_TYPE" == "primary" ]; then
        echo "Instalando K3s como nó primário..."
        curl -sfL https://get.k3s.io | sudo INSTALL_K3S_EXEC="server --cluster-init --datastore-endpoint=etcd" sh -
        echo "K3s nó primário instalado com sucesso."
    elif [ "$NODE_TYPE" == "secondary" ]; then
        if [ -z "$ETCD_ENDPOINT" ] || [ -z "$TOKEN" ]; then
            echo "Para adicionar um nó secundário, é necessário fornecer o endpoint do ETCD e o token."
            exit 1
        fi
        echo "Instalando K3s como nó secundário..."
        curl -sfL https://get.k3s.io | sudo INSTALL_K3S_EXEC="server --server https://$ETCD_ENDPOINT:6443 --token $TOKEN" sh -
        echo "K3s nó secundário instalado com sucesso."
    else
        echo "Tipo de nó inválido. Use 'primary' para o primeiro nó ou 'secondary' para adicionar um nó ao cluster."
        exit 1
    fi
}

# Função principal
main() {
    if [ "$#" -lt 1 ]; then
        echo "Uso: $0 <primary|secondary> [ETCD_ENDPOINT] [TOKEN]"
        exit 1
    fi

    NODE_TYPE=$1
    ETCD_ENDPOINT=$2
    TOKEN=$3

    install_docker
    install_k3s $NODE_TYPE $ETCD_ENDPOINT $TOKEN
    install_portainer
}

# Executa o script principal
main "$@"
