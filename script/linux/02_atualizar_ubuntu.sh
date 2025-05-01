#!/bin/bash

# Script para atualizar e limpar o sistema Ubuntu

# Configurações
ALLOWED_USER=${ALLOWED_USER:-"root"}
LOG_FILE="/var/log/system-update.log"
MIN_DISK_SPACE=500  # MB

# Verifica privilégios de administrador
if ! sudo -n true 2>/dev/null; then
    echo "Erro: Este script requer privilégios de administrador (sudo)"
    exit 1
fi

# Verifica se o usuário é permitido
if [ "$(whoami)" != "$ALLOWED_USER" ]; then
    echo "Erro: Este script deve ser executado pelo usuário $ALLOWED_USER."
    exit 1
fi

# Verifica se o sistema é baseado em Debian/Ubuntu
if ! command -v apt >/dev/null 2>&1; then
    echo "Erro: Este script é projetado para sistemas baseados em Debian/Ubuntu"
    exit 1
fi

# Verifica espaço em disco
AVAILABLE_SPACE=$(df -m / | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_SPACE" -lt "$MIN_DISK_SPACE" ]; then
    echo "Erro: Espaço em disco insuficiente ($AVAILABLE_SPACE MB disponível, $MIN_DISK_SPACE MB necessário)"
    exit 1
fi

# Verifica conexão com a internet
if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "Erro: Sem conexão com a internet"
    exit 1
fi

# Atualiza a lista de pacotes disponíveis
echo "Atualizando a lista de pacotes..."
sudo apt update >>"$LOG_FILE" 2>&1 || { echo "Erro: Falha ao atualizar a lista de pacotes, consulte $LOG_FILE"; exit 1; }

# Atualiza os pacotes instalados
echo "Atualizando os pacotes instalados..."
sudo apt upgrade -y >>"$LOG_FILE" 2>&1 || { echo "Erro: Falha ao atualizar pacotes, consulte $LOG_FILE"; exit 1; }

# Realiza a atualização de distribuição
echo "Realizando a atualização de distribuição..."
read -p "Deseja executar 'dist-upgrade' (pode instalar/remover pacotes)? (s/n): " confirm
if [[ "$confirm" =~ ^[Ss]$ ]]; then
    sudo apt dist-upgrade >>"$LOG_FILE" 2>&1 || { echo "Erro: Falha na atualização de distribuição, consulte $LOG_FILE"; exit 1; }
else
    echo "Pulando dist-upgrade."
fi

# Remove pacotes desnecessários
echo "Removendo pacotes desnecessários..."
sudo apt autoremove -y >>"$LOG_FILE" 2>&1 || { echo "Erro: Falha ao remover pacotes desnecessários, consulte $LOG_FILE"; exit 1; }

# Limpa o cache do APT
echo "Limpando o cache do APT..."
sudo apt clean >>"$LOG_FILE" 2>&1 || { echo "Erro: Falha ao limpar o cache do APT, consulte $LOG_FILE"; exit 1; }

# Verifica se é necessário reiniciar
if [ -f /var/run/reboot-required ]; then
    echo "Aviso: É necessário reiniciar o sistema para aplicar algumas atualizações."
fi

echo "Atualização concluída com sucesso!"