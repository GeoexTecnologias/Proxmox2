#!/bin/bash

# Atualiza o timezone
echo "Atualizando o timezone para America/Bahia"
sudo timedatectl set-timezone America/Bahia

echo "Iniciando a instalação do K3s com etcd no servidor controlador..."

# Atualiza o sistema
sudo apt update && sudo apt upgrade -y

echo "Instalando o K3s com etcd como datastore..."
# Instala o K3s com etcd como datastore
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --datastore-endpoint='etcd'" sh -

# Exporte a variável KUBECONFIG para usar o kubectl
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Aguarde o K3s inicializar
sleep 10

# Instala o Helm
echo "Instalando o Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Adiciona o repositório do Portainer no Helm
echo "Adicionando o repositório do Portainer no Helm..."
helm repo add portainer https://portainer.github.io/k8s/

# Atualiza os repositórios do Helm
helm repo update

# Cria o namespace para o Portainer
echo "Criando o namespace para o Portainer..."
kubectl create namespace portainer

# Instala o Portainer via Helm com tolerância para rodar no nó controlador, sem expor serviços desnecessários
echo "Instalando o Portainer no K3s via Helm..."
helm install portainer portainer/portainer -n portainer \
  --set service.type=NodePort \
  --set service.ports.http.enabled=false \
  --set service.ports.https.enabled=true \
  --set service.ports.https.port=9443 \
  --set service.ports.https.nodePort=9443

echo "Instalação concluída!"
echo "K3s server com etcd e Portainer instalados no controlador k3s."
echo "Token para conectar os nós ao controlador:"
sudo cat /var/lib/rancher/k3s/server/node-token

# Exibe o IP para conexão ao Portainer
echo "Conecte-se ao Portainer em https://$(hostname -I | awk '{print $1}'):9443"
