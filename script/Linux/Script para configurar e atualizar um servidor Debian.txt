#!/bin/bash

# Script para configurar e atualizar um servidor Debian

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Use sudo."
  exit 1
fi

# Define o usuário e a senha
USERNAME="aguiar"
PASSWORD="sysdm.cpl"

# Cria ou atualiza o usuário com a senha especificada
echo "Configurando usuário $USERNAME..."
echo "$USERNAME:$PASSWORD" | chpasswd

# Faz backup do arquivo sources.list original
cp /etc/apt/sources.list /etc/apt/sources.list.bak

# Configura um repositório Debian válido (usando o mirror oficial)
echo "Configurando repositórios de atualização..."
cat > /etc/apt/sources.list << EOL
deb http://deb.debian.org/debian stable main contrib non-free
deb-src http://deb.debian.org/debian stable main contrib non-free

deb http://deb.debian.org/debian stable-updates main contrib non-free
deb-src http://deb.debian.org/debian stable-updates main contrib non-free

deb http://deb.debian.org/debian-security stable-security main contrib non-free
deb-src http://deb.debian.org/debian-security stable-security main contrib non-free
EOL

# Atualiza a lista de pacotes
echo "Atualizando lista de pacotes..."
apt update

# Realiza a atualização do sistema
echo "Atualizando o sistema..."
apt upgrade -y

# Remove pacotes desnecessários
echo "Limpando pacotes desnecessários..."
apt autoremove -y

# Verifica se houve erros na atualização
if [ $? -eq 0 ]; then
  echo "Atualização concluída com sucesso!"
else
  echo "Houve um erro durante a atualização. Verifique os logs."
  exit 1
fi

echo "Script concluído. O sistema está atualizado."