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

# Função para instalar o Portainer
install_portainer() {
    echo "Instalando Portainer..."
    docker volume create portainer_data
    docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data portainer/portainer-ce:latest
    echo "Portainer instalado com sucesso."

    # Aguarda o Portainer estar pronto
    echo "Aguardando o Portainer iniciar..."
    sleep 15

    # Configurar o usuário admin do Portainer
    configure_portainer_admin
    configure_portainer
}

# Função para configurar o usuário admin do Portainer
configure_portainer_admin() {
    echo "Configurando o usuário admin do Portainer..."
    ADMIN_PASSWORD="@docker" # Defina a senha desejada aqui
    until curl -k -s https://localhost:9443/api/status > /dev/null; do
        echo "Aguardando o Portainer iniciar para configurar o admin..."
        sleep 5
    done

    # Cria o usuário admin
    curl -k -X POST "https://localhost:9443/api/users/admin/init" -H "Content-Type: application/json" \
        --data "{\"Username\":\"admin\",\"Password\":\"$ADMIN_PASSWORD\"}"
    echo "Usuário admin configurado com sucesso."
}

# Função para configurar o Portainer para gerenciar o K3s local
configure_portainer() {
    echo "Configurando o Portainer para gerenciar o K3s localmente..."

    # Espera um pouco para garantir que o admin esteja configurado
    sleep 10

    # Ler o arquivo de configuração do K3s e ajustar o servidor conforme necessário
    KUBECONFIG_CONTENT=$(sudo cat /etc/rancher/k3s/k3s.yaml | sed "s/127.0.0.1/<IP_DO_SERVIDOR>/g")

    # Adiciona o ambiente Kubernetes no Portainer
    ADMIN_PASSWORD="admin" # Mesma senha definida anteriormente
    curl -k -X POST "https://localhost:9443/api/endpoints" -H "Content-Type: application/json" -H "X-Portainer-API-Key: $ADMIN_PASSWORD" \
        --data "{\"Name\":\"Local K3s\",\"URL\":\"unix:///var/run/docker.sock\",\"GroupID\":1,\"PublicURL\":\"\",\"TLS\":false,\"TLSSkipVerify\":true,\"Type\":5,\"KubeConfigContent\":\"$KUBECONFIG_CONTENT\"}"
    echo "Portainer configurado para gerenciar o K3s localmente."
}

# Função para instalar o K3s com etcd como datastore
install_k3s_server() {
    echo "Instalando K3s server com etcd..."
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init --datastore-endpoint='etcd'" sh -
    echo "K3s server com etcd instalado com sucesso."
    echo "Token para adicionar agents: $(cat /var/lib/rancher/k3s/server/node-token)"
}

# Função principal
main() {
    install_docker
    install_k3s_server
    install_portainer
}

# Executa o script principal
main
