#!/bin/bash

# Variáveis de configuração
DOMAIN="intus.local"
DNS_IP="192.168.6.249"
ADMIN_USER="itconnectadm"  # Substitua pelo usuário do domínio com permissões
ADMIN_PASS="96PO08as@!!(&(4132"    # Substitua pela senha do administrador do domínio
NEW_COMPUTER_NAME="MacbookPRO_0001"  # Nome do computador com até 15 caracteres
OU="OU=Computers,DC=intus,DC=local"  # Ajuste conforme a estrutura do seu AD

# Verifica se o usuário tem permissões de administrador local
if [[ $EUID -ne 0 ]]; then
   echo "Este script precisa ser executado como root. Use 'sudo'."
   exit 1
fi

# Verifica o nome atual do computador
CURRENT_COMPUTER_NAME=$(scutil --get ComputerName)
if [ ${#CURRENT_COMPUTER_NAME} -gt 15 ]; then
    echo "O nome do computador ($CURRENT_COMPUTER_NAME) excede 15 caracteres. Alterando para $NEW_COMPUTER_NAME..."
    sudo scutil --set ComputerName "$NEW_COMPUTER_NAME"
    sudo scutil --set HostName "$NEW_COMPUTER_NAME"
    sudo scutil --set LocalHostName "$NEW_COMPUTER_NAME"
else
    NEW_COMPUTER_NAME="$CURRENT_COMPUTER_NAME"
fi

# Configura o servidor DNS para Wi-Fi
echo "Configurando o DNS para $DNS_IP..."
networksetup -setdnsservers Wi-Fi $DNS_IP

# Verifica se o DNS foi configurado corretamente
echo "Verificando configuração do DNS..."
scutil --dns

# Verifica conectividade com o domínio
echo "Testando conectividade com o domínio $DOMAIN..."
if ! ping -c 2 $DOMAIN > /dev/null 2>&1; then
    echo "Erro: Não foi possível alcançar o domínio $DOMAIN. Verifique a conectividade de rede e o DNS."
    exit 1
fi

# Adiciona o MacBook ao domínio
echo "Adicionando o MacBook ao domínio $DOMAIN..."
dsconfigad -f -a "$NEW_COMPUTER_NAME" -domain "$DOMAIN" -u "$ADMIN_USER" -p "$ADMIN_PASS" -ou "$OU"

# Verifica se a adição ao domínio foi bem-sucedida
if [ $? -eq 0 ]; then
    echo "MacBook adicionado ao domínio $DOMAIN com sucesso!"
else
    echo "Erro ao adicionar o MacBook ao domínio. Verifique as credenciais, o nome do computador e a conectividade."
    exit 1
fi

# Habilita o cache de credenciais móveis (opcional, para login offline)
echo "Habilitando cache de credenciais móveis..."
dsconfigad -mobile enable
dsconfigad -mobileconfirm enable

# Reinicia o serviço de Directory Services
echo "Reiniciando serviços de diretório..."
killall DirectoryService

echo "Configuração concluída! Reinicie o MacBook para aplicar as alterações."