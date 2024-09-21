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

echo "Instalando Portainer Agent no K3s..."

kubectl apply -f https://downloads.portainer.io/ce2-21/portainer-agent-k8s-nodeport.yaml

echo "Portainer Agent instalado. O agente agora está rodando no servidor."

echo "Token"
cat /var/lib/rancher/k3s/server/node-token
