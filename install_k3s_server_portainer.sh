#!/bin/bash

# Atualiza o timezone
echo "Atualizando o timezone para America/Bahia"
sudo timedatectl set-timezone America/Bahia

echo "Iniciando a instalação do K3s com etcd no servidor controlador..."

# Atualiza o sistema
sudo apt update && sudo apt upgrade -y

echo "Instalando o K3s com etcd como datastore..."
# Instala o K3s com etcd como datastore e desabilita o agente
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable-agent --datastore-endpoint='etcd'" sh -

# Exporte a variável KUBECONFIG para usar o kubectl
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Aguarde o K3s inicializar
sleep 10

# Adiciona taint ao nó controlador para impedir que outros pods sejam agendados, exceto o Portainer
echo "Configurando o nó controlador para aceitar apenas o Portainer..."
kubectl taint nodes $(hostname) dedicated=controller:NoSchedule

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

# Instala o Portainer via Helm com tolerância para rodar no nó controlador
echo "Instalando o Portainer no K3s via Helm..."
helm install portainer portainer/portainer -n portainer \
  --set tolerations[0].key="dedicated" \
  --set tolerations[0].operator="Equal" \
  --set tolerations[0].value="controller" \
  --set tolerations[0].effect="NoSchedule" \
  --set service.type=LoadBalancer

echo "Instalação concluída!"
echo "K3s server com etcd e Portainer instalados no controlador k3s."
echo "Token para conectar os nós ao controlador:"
sudo cat /var/lib/rancher/k3s/server/node-token

# Exibe o IP para conexão ao Portainer
echo "Conecte-se ao Portainer em https://$(hostname -I | awk '{print $1}'):9443"
