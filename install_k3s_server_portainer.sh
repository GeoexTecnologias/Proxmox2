#!/bin/bash

echo "Atualizando o sistema..."
apk update && apk upgrade

echo "Instalando dependências..."
apk add curl iptables ip6tables socat

echo "Instalando K3s com etcd como datastore..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init --datastore-endpoint=etcd" sh -

echo "Verificando o status do K3s..."
systemctl status k3s

echo "Configurando K3s para iniciar automaticamente..."
rc-update add k3s default

echo "Instalando Docker para o Portainer agent..."
apk add docker
service docker start
rc-update add docker

echo "Instalando Portainer agent..."
docker volume create portainer_data
docker run -d \
    -p 9001:9001 \
    --name portainer_agent \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/agent

echo "Instalação concluída no servidor."
