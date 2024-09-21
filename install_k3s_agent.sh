#!/bin/bash

# Definir os parâmetros
IP_SERVIDOR=$1
TOKEN_SERVIDOR=$2

if [ -z "$IP_SERVIDOR" ] || [ -z "$TOKEN_SERVIDOR" ]; then
  echo "Uso: $0 <IP_DO_SERVIDOR> <TOKEN_DO_SERVIDOR>"
  exit 1
fi

echo "Atualizando o sistema..."
apk update && apk upgrade

echo "Instalando dependências..."
apk add curl iptables ip6tables socat

echo "Instalando K3s agent e conectando ao servidor $IP_SERVIDOR..."
curl -sfL https://get.k3s.io | K3S_URL=https://$IP_SERVIDOR:6443 K3S_TOKEN=$TOKEN_SERVIDOR sh -

echo "Verificando o status do K3s agent..."
rc-service k3s-agent status

echo "Configurando K3s agent para iniciar automaticamente..."
rc-update add k3s-agent default

echo "Instalação concluída no nó."
