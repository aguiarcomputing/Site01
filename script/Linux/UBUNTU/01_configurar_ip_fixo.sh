#!/bin/bash

# Script para configurar IP fixo em uma interface de rede

# Default values
IP_ADDRESS="192.168.2.110/24"
GATEWAY="192.168.2.1"
DNS_SERVERS="192.168.2.252,8.8.8.8"
CONFIG_FILE="/etc/netplan/01-netcfg.yaml"

# Função para detectar interface de rede ativa
detect_interface() {
    # Lista interfaces ativas (exceto loopback)
    local interfaces
    interfaces=$(ip link show | grep -E '^[0-9]+: ' | grep -v 'lo:' | grep 'state UP' | awk '{print $2}' | cut -d':' -f1)
    
    if [ -z "$interfaces" ]; then
        echo "Nenhuma interface de rede ativa encontrada."
        echo "Por favor, especifique a interface manualmente:"
        ip link show | grep -E '^[0-9]+: ' | grep -v 'lo:' | awk '{print $2}' | cut -d':' -f1
        read -p "Digite o nome da interface: " INTERFACE
        if ! ip link show "$INTERFACE" &> /dev/null; then
            echo "Interface $INTERFACE inválida. Encerrando."
            exit 1
        fi
    else
        # Pega a primeira interface ativa
        INTERFACE=$(echo "$interfaces" | head -n 1)
        echo "Interface detectada: $INTERFACE"
    fi
}

# Verifica se o usuário é root
if [ "$EUID" -ne 0 ]; then
    echo "Este script precisa ser executado como root (use sudo)"
    exit 1
fi

# Verifica se o Netplan está instalado
if ! command -v netplan &> /dev/null; then
    echo "Netplan não está instalado. Este script requer Netplan."
    exit 1
fi

# Detecta a interface de rede
detect_interface

# Cria backup do arquivo de configuração atual, se existir
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
    echo "Backup criado em $CONFIG_FILE.bak"
fi

# Cria a nova configuração
cat > "$CONFIG_FILE" << EOL
network:
  version: 2
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses:
        - $IP_ADDRESS
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses:
$(for dns in ${DNS_SERVERS//,/ }; do echo "          - $dns"; done)
EOL

# Verifica se o arquivo foi criado corretamente
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Erro ao criar o arquivo de configuração $CONFIG_FILE"
    exit 1
fi

# Ajusta as permissões do arquivo
chmod 600 "$CONFIG_FILE"

# Aplica as configurações
if ! netplan apply; then
    echo "Erro ao aplicar a configuração. Restaurando backup..."
    if [ -f "$CONFIG_FILE.bak" ]; then
        mv "$CONFIG_FILE.bak" "$CONFIG_FILE"
        netplan apply
    fi
    exit 1
fi

echo "Configuração de IP fixo aplicada!"
echo "Interface: $INTERFACE"
echo "IP: $IP_ADDRESS"
echo "Gateway: $GATEWAY"
echo "DNS: $DNS_SERVERS"
echo "Verifique a conectividade com 'ping $GATEWAY'"