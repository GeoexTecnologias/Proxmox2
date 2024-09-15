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

# Função para instalar o K3s com etcd como datastore
install_k3s_server() {
    echo "Instalando K3s server com etcd..."
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init --datastore-endpoint='etcd'" sh -
    echo "K3s server com etcd instalado com sucesso."
    echo "Token para adicionar agents: $(cat /var/lib/rancher/k3s/server/node-token)"
}

# Função para instalar o Portainer no K3s
install_portainer_on_k3s() {
    echo "Instalando o Portainer no K3s..."

    # Baixar o arquivo YAML do Portainer e aplicá-lo ao cluster K3s
    kubectl apply -f https://downloads.portainer.io/ce2-17/portainer-ce.yaml

    # Esperar até que o Portainer esteja implantado e pronto
    echo "Aguardando o Portainer ficar pronto..."
    kubectl wait --namespace portainer --for=condition=available --timeout=120s deployment/portainer

    echo "Portainer instalado no K3s com sucesso."
    echo "Acesse o Portainer em: http://<IP_DO_SERVIDOR>:30777"
}

# Função principal
main() {
    install_docker
    install_k3s_server
    install_portainer_on_k3s
}

# Executa o script principal
main
