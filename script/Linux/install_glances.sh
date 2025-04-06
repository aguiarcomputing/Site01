#!/bin/bash

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Use sudo."
  exit 1
fi

# Atualiza o sistema
echo "Atualizando o sistema..."
apt update && apt upgrade -y

# Instala o Glances
echo "Instalando o Glances..."
apt install glances -y

# Instala o pip e a versão mais recente do Glances (opcional)
echo "Instalando pip e atualizando o Glances..."
apt install python3-pip -y
pip3 install --upgrade glances

# Cria o usuário 'aguiar' e define a senha 'sysdm.cpl'
echo "Criando usuário 'aguiar'..."
useradd -m -s /bin/bash aguiar
echo "aguiar:sysdm.cpl" | chpasswd
echo "Usuário 'aguiar' criado com sucesso!"

# Configura o IP estático (assumindo interface 'eth0', ajuste conforme necessário)
echo "Configurando IP estático 192.168.2.129..."
cat <<EOL > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 192.168.2.129/24
      gateway4: 192.168.2.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOL
netplan apply
echo "IP configurado como 192.168.2.129."

# Configura o firewall (UFW) para liberar a porta do Glances (61209 para modo servidor)
echo "Configurando o firewall..."
apt install ufw -y
ufw allow 61209/tcp
ufw enable
ufw status
echo "Firewall configurado para permitir Glances na porta 61209."

# Inicia o Glances em modo servidor como exemplo (opcional)
echo "Iniciando Glances em modo servidor (teste)..."
echo "Para uso contínuo, configure um serviço systemd."
su - aguiar -c "glances -s &"

echo "Instalação e configuração concluídas!"
echo "Acesse o Glances remotamente com: glances -c 192.168.2.129"
