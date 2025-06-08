#!/bin/bash

# Script para configurar IP fixo com base no IP obtido via DHCP

# Arquivo de configuração do Netplan
CONFIG_FILE="/etc/netplan/01-netcfg.yaml"

# Função para exibir mensagens de erro e sair
error_exit() {
    echo "Erro: $1" >&2
    exit 1
}

# Função para detectar interface de rede ativa
detect_interface() {
    local interfaces
    interfaces=$(ip link show | grep -E '^[0-9]+: ' | grep -v 'lo:' | grep 'state UP' | awk '{print $2}' | cut -d':' -f1)
    
    if [ -z "$interfaces" ]; then
        echo "Nenhuma interface de rede ativa encontrada."
        ip link show | grep -E '^[0-9]+: ' | grep -v 'lo:' | awk '{print $2}' | cut -d':' -f1
        read -p "Digite o nome da interface: " INTERFACE
    elif [ -n "$1" ]; then
        INTERFACE="$1"
    else
        INTERFACE=$(echo "$interfaces" | head -n 1)
        echo "Interface detectada: $INTERFACE"
    fi

    if ! ip link show "$INTERFACE" &> /dev/null; then
        error_exit "Interface $INTERFACE inválida."
    fi
}

# Função para obter configurações do DHCP
get_dhcp_info() {
    # Obtém o IP e a máscara da interface
    IP_ADDRESS=$(ip -4 addr show "$INTERFACE" | grep inet | awk '{print $2}' | head -n 1)
    if [ -z "$IP_ADDRESS" ]; then
        error_exit "Não foi possível obter o endereço IP da interface $INTERFACE."
    fi

    # Obtém o gateway
    GATEWAY=$(ip route show | grep default | grep "$INTERFACE" | awk '{print $3}' | head -n 1)
    if [ -z "$GATEWAY" ]; then
        GATEWAY="192.168.1.1" # Fallback caso não seja encontrado
        echo "Gateway não encontrado. Usando padrão: $GATEWAY"
    fi

    # Obtém os servidores DNS
    DNS_SERVERS=$(nmcli -t -f IP4.DNS dev show "$INTERFACE" | awk -F':' '{print $2}' | tr '\n' ',' | sed 's/,$//')
    if [ -z "$DNS_SERVERS" ]; then
        DNS_SERVERS="8.8.8.8,8.8.4.4" # Fallback caso não seja encontrado
        echo "Servidores DNS não encontrados. Usando padrão: $DNS_SERVERS"
    fi
}

# Verifica se o usuário é root
if [ "$EUID" -ne 0 ]; then
    error_exit "Este script precisa ser executado como root (use sudo)."
fi

# Verifica se o Netplan está instalado
if ! command -v netplan &> /dev/null; then
    error_exit "Netplan não está instalado. Este script requer Netplan."
fi

# Verifica se nmcli está instalado para obter informações do DHCP
if ! command -v nmcli &> /dev/null; then
    echo "Aviso: nmcli não está instalado. Algumas informações do DHCP podem não ser obtidas."
fi

# Detecta a interface de rede (passa o primeiro argumento, se fornecido)
detect_interface "$1"

# Obtém as informações do DHCP
get_dhcp_info

# Cria backup do arquivo de configuração atual, se existir
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak-$(date +%F_%H-%M-%S)"
    echo "Backup criado em $CONFIG_FILE.bak-$(date +%F_%H-%M-%S)"
fi

# Cria a nova configuração do Netplan
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
    error_exit "Erro ao criar o arquivo de configuração $CONFIG_FILE."
fi

# Ajusta as permissões do arquivo
chmod 600 "$CONFIG_FILE"

# Testa a configuração antes de aplicar
if ! netplan try --timeout 120; then
    echo "Erro ao aplicar a configuração. Restaurando backup..."
    if ls "$CONFIG_FILE.bak-"* &> /dev/null; then
        latest_backup=$(ls -t "$CONFIG_FILE.bak-"* | head -n 1)
        mv "$latest_backup" "$CONFIG_FILE"
        netplan apply
    fi
    error_exit "Configuração não aplicada."
fi

# Aplica as configurações
netplan apply

echo "Configuração de IP fixo aplicada com sucesso!"
echo "Interface: $INTERFACE"
echo "IP: $IP_ADDRESS"
echo "Gateway: $GATEWAY"
echo "DNS: $DNS_SERVERS"
echo "Verifique a conectividade com 'ping $GATEWAY'"