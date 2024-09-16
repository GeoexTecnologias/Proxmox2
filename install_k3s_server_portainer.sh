#!/bin/bash

# Atualiza o timezone
echo "Atualizando o timezone para America/Bahia"
sudo timedatectl set-timezone America/Bahia

echo "Iniciando a instalação do K3s com etcd no servidor controlador..."

# Atualiza o sistema
sudo apt update && sudo apt upgrade -y

echo "Instalando o K3s com etcd como datastore..."
# Instala o K3s com etcd como datastore
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable-agent --datastore-endpoint='etcd'" sh -

# Exporte a variável KUBECONFIG para usar o kubectl
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "Instalando o Docker para o Portainer..."
# Instala o Docker (necessário para Portainer)
sudo apt install -y docker.io

echo "Instalando o Portainer..."
# Instala o Portainer
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 --name=portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce

echo "Instalação concluída!"
echo "K3s server com etcd e Portainer instalados."

# Exibe o token gerado para conectar os nós ao controlador
echo "Token para conectar os nós ao controlador:"
sudo cat /var/lib/rancher/k3s/server/node-token

echo "Conecte-se ao Portainer em https://$(hostname -I | awk '{print $1}'):9443"
