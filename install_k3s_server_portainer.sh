#!/bin/bash

echo "Atualizando o sistema..."
apk update && apk upgrade

echo "Instalando dependências necessárias..."
apk add curl iptables ip6tables socat

echo "Instalando K3s com etcd como datastore..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init --datastore-endpoint=etcd" sh -

echo "Verificando o status do K3s (comando 'rc-service')..."
rc-service k3s status

echo "Instalando Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "Instalando Portainer Agent via Helm no K3s..."

# Adicionar o repositório do Portainer
helm repo add portainer https://portainer.github.io/k8s/

# Atualizar os repositórios
helm repo update

# Instalar o Portainer Agent no namespace portainer-agent
helm install portainer-agent portainer/portainer-agent \
  --create-namespace \
  --namespace portainer-agent \
  --set agent.enabled=true

echo "Portainer Agent instalado. O agente agora está rodando no servidor."
