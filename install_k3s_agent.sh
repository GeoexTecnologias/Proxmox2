#!/bin/bash

# Atualiza o timezone
echo "Atualizando o timezone para America/Bahia"
sudo timedatectl set-timezone America/Bahia

# Verifica se os parâmetros foram passados
if [ $# -ne 2 ]; then
  echo "Uso: $0 <IP_DO_CONTROLADOR> <TOKEN>"
  exit 1
fi

# Atribui os parâmetros às variáveis
IP_DO_CONTROLADOR=$1
TOKEN=$2

echo "Iniciando a instalação do K3s agent no nó..."

# Atualiza o sistema
sudo apt update && sudo apt upgrade -y

# Testa a conectividade com o controlador
echo "Testando conectividade com o controlador..."
if ! curl -k https://$IP_DO_CONTROLADOR:6443 > /dev/null 2>&1; then
  echo "Erro: Não foi possível conectar ao controlador em https://$IP_DO_CONTROLADOR:6443"
  exit 1
fi

echo "Conectividade OK. Instalando o K3s agent e conectando ao controlador..."
# Instala o K3s agent e conecta ao controlador usando os parâmetros fornecidos
K3S_URL=https://$IP_DO_CONTROLADOR:6443 K3S_TOKEN=$TOKEN curl -sfL https://get.k3s.io | sh -s - agent --token $TOKEN

echo "Instalação concluída!"
echo "K3s agent instalado neste nó."
echo "Este nó agora está conectado ao controlador em https://$IP_DO_CONTROLADOR:6443"
