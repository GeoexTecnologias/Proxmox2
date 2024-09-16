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

# Função para instalar o K3s server
install_k3s_server() {
    if [ "$IS_PRIMARY" = "true" ]; then
        echo "Instalando K3s server com etcd como nó principal..."
        curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init --datastore-endpoint='etcd'" sh -
    else
        echo "Instalando K3s server e adicionando ao cluster existente..."
        curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --server https://$PRIMARY_SERVER:6443 --token $TOKEN" sh -
    fi
    echo "K3s server instalado com sucesso."
}

# Função para instalar o Helm
install_helm() {
    echo "Instalando o Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "Helm instalado com sucesso."
}

# Função para instalar o Portainer no K3s usando Helm (somente no nó principal)
install_portainer_on_k3s() {
    if [ "$IS_PRIMARY" = "true" ]; then
        echo "Instalando o Portainer no K3s usando Helm..."
        
        # Definindo o KUBECONFIG para garantir que o Helm use o kubeconfig correto
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

        # Adiciona o repositório oficial do Portainer
        helm repo add portainer https://portainer.github.io/k8s/
        helm repo update

        # Cria a namespace para o Portainer
        kubectl create namespace portainer

        # Instala o Portainer na namespace "portainer"
        helm install portainer portainer/portainer --namespace portainer --set service.type=NodePort --set service.nodePort=30777

        echo "Aguardando o Portainer ficar pronto..."
        kubectl wait --namespace portainer --for=condition=available --timeout=120s deployment/portainer

        echo "Portainer instalado no K3s com sucesso."
        echo "Acesse o Portainer em: http://<IP_DO_SERVIDOR>:30777"
    fi
}

# Função principal para coordenar as instalações
main() {
    # Solicita ao usuário se este é o nó principal ou um nó adicional
    read -p "Este é o nó principal? (yes/no): " RESPONSE
    if [[ "$RESPONSE" == "yes" ]]; then
        IS_PRIMARY=true
    else
        IS_PRIMARY=false
        # Se for um nó adicional, solicitar o IP do servidor principal e o token
        read -p "Informe o IP do servidor principal: " PRIMARY_SERVER
        read -p "Informe o token do K3s: " TOKEN
    fi

    # Instalar Docker, K3s e Helm
    install_docker
    install_k3s_server
    install_helm

    # Se for o nó principal, instalar o Portainer dentro do K3s
    install_portainer_on_k3s
}

# Executa a função principal
main
