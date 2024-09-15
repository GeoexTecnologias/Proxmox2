Executar primário

```
curl -sSL https://raw.githubusercontent.com/GeoexTecnologias/Proxmox2/developer/install_k3s_server_portainer.sh | sudo bash -s
sudo cat /var/lib/rancher/k3s/server/node-token
```

Executar nó
```
curl -sSL https://raw.githubusercontent.com/GeoexTecnologias/Proxmox2/developer/install_k3s_agent.sh | sudo bash -s <IP_DO_SERVIDOR> <TOKEN>
```
