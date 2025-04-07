#!/bin/bash

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    echo "Por favor, execute este script como root (use sudo)"
    exit 1
fi

# Atualiza o sistema
echo "Atualizando o sistema..."
apt update && apt upgrade -y

# Instala dependências necessárias
echo "Instalando dependências..."
apt install -y wget gnupg

# Adiciona a chave GPG do Webmin
echo "Adicionando chave GPG do Webmin..."
wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -

# Adiciona o repositório do Webmin ao sources.list
echo "Adicionando repositório do Webmin..."
echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list

# Atualiza a lista de pacotes
echo "Atualizando lista de pacotes..."
apt update

# Instala o Webmin
echo "Instalando o Webmin..."
apt install -y webmin

# Verifica o status do serviço
echo "Verificando status do Webmin..."
systemctl status webmin

echo "Instalação concluída!"
echo "Você pode acessar o Webmin em: https://SEU_IP:10000"
echo "Use as credenciais de root ou de um usuário com privilégios sudo"
