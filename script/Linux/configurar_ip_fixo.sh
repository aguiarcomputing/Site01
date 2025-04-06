#!/bin/bash

# Script para configurar IP fixo em enp0s3

# Verifica se o usuário é root
if [ "$EUID" -ne 0 ]; then
    echo "Este script precisa ser executado como root (use sudo)"
    exit 1
fi

# Cria backup do arquivo de configuração atual, se existir
CONFIG_FILE="/etc/netplan/01-netcfg.yaml"
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
    echo "Backup criado em $CONFIG_FILE.bak"
fi

# Cria a nova configuração
cat > "$CONFIG_FILE" << EOL
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses:
        - 192.168.2.126/24
      gateway4: 192.168.2.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
EOL

# Ajusta as permissões do arquivo
chmod 600 "$CONFIG_FILE"

# Aplica as configurações
netplan apply

echo "Configuração de IP fixo aplicada!"
echo "IP: 192.168.2.126/24"
echo "Gateway: 192.168.2.1"
echo "DNS: 8.8.8.8, 8.8.4.4"
echo "Verifique a conectividade com 'ping 8.8.8.8'"
