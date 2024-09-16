#!/bin/bash

# Função para exibir o uso correto do script
usage() {
    echo "Uso: $0 --mode <primary|secondary> [--primary-ip <IP_DO_PRINCIPAL>] [--token <TOKEN>]"
    echo ""
    echo "Parâmetros:"
    echo "  --mode          Define se o nó é o 'primary' (principal) ou 'secondary' (adicional)."
    echo "  --primary-ip    IP do nó principal (necessário para adicionar um nó secundário)."
    echo "  --token         Token do K3s para adicionar ao cluster (necessário para adicionar um nó secundário)."
    echo ""
    echo "Exemplos:"
    echo "  $0 --mode primary"
    echo "  $0 --mode secondary --primary-ip 192.168.1.10 --token <TOKEN>"
    exit 1
}

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
    if [ "$MODE" = "primary" ]; then
        echo "Instalando K3s server com etcd como nó principal..."
        curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init --datastore-endpoint='etcd'" sh -
        echo "K3s server instalado com sucesso."
        # Exibe o token gerado para adicionar nós secundários ao cluster
        TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
        echo "Token para adicionar nós secundários: $TOKEN"
    else
        echo "Instalando K3s server e adicionando ao cluster existente..."
        curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --server https://$PRIMARY_IP:6443 --token $TOKEN" sh -
        echo "K3s server instalado com sucesso."
    fi
}

# Função para instalar o Helm
install_helm() {
    echo "Instalando o Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "Helm instalado com sucesso."
}

# Função para instalar o Portainer no K3s usando Helm (somente no nó principal)
install_portainer_on_k3s() {
    if [ "$MODE" = "primary" ]; then
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

# Processa os parâmetros da linha de comando
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --mode) MODE="$2"; shift ;;
        --primary-ip) PRIMARY_IP="$2"; shift ;;
        --token) TOKEN="$2"; shift ;;
        *) echo "Parâmetro desconhecido: $1"; usage ;;
    esac
    shift
done

# Valida os parâmetros obrigatórios
if [ -z "$MODE" ]; then
    echo "Erro: O modo (--mode) é obrigatório."
    usage
fi

if [ "$MODE" = "secondary" ] && ( [ -z "$PRIMARY_IP" ] || [ -z "$TOKEN" ] ); then
    echo "Erro: Para adicionar um nó secundário, você deve fornecer --primary-ip e --token."
    usage
fi

# Função principal para coordenar as instalações
main() {
    # Instalar Docker, K3s e Helm
    install_docker
    install_k3s_server
    install_helm

    # Se for o nó principal, instalar o Portainer dentro do K3s
    install_portainer_on_k3s
}

# Executa a função principal
main
