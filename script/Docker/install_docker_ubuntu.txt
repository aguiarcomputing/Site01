#!/bin/bash

# Script para verificar, instalar, remover e limpar Docker no Ubuntu Server

# Arquivo de log para depuração
LOG_FILE="/tmp/docker-install.log"

# Função para verificar privilégios de administrador
check_privileges() {
    if ! command -v sudo >/dev/null 2>&1 || ! sudo -n true 2>/dev/null; then
        echo "Erro: Este script requer privilégios de administrador (sudo)"
        exit 1
    fi
}

# Função para verificar conexão com a internet
check_internet() {
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "Erro: Sem conexão com a internet"
        exit 1
    fi
}

# Função para verificar requisitos do sistema
check_requirements() {
    echo "Verificando requisitos do sistema..."

    # Verifica se é Ubuntu
    if ! lsb_release -a 2>/dev/null | grep -q "Ubuntu"; then
        echo "Erro: Este script é projetado para Ubuntu Server"
        exit 1
    fi

    # Verifica codinome do Ubuntu
    CODENAME=$(lsb_release -cs 2>/dev/null)
    if [[ -z "$CODENAME" || ! "$CODENAME" =~ ^(focal|jammy|noble)$ ]]; then
        echo "Erro: Codinome do Ubuntu ($CODENAME) não suportado ou não detectado"
        exit 1
    fi

    # Verifica arquitetura
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" && "$ARCH" != "armhf" && "$ARCH" != "s390x" ]]; then
        echo "Erro: Arquitetura $ARCH não suportada"
        exit 1
    fi

    # Verifica memória (mínimo 2GB recomendado)
    TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$TOTAL_MEM" -lt 2000 ]; then
        echo "Aviso: Memória RAM ($TOTAL_MEM MB) abaixo do recomendado (2GB)"
    fi

    # Verifica se kernel é recente (mínimo 3.10)
    KERNEL_VERSION=$(uname -r | cut -d'.' -f1-2)
    if [[ "$KERNEL_VERSION" < "3.10" ]]; then
        echo "Erro: Versão do kernel $KERNEL_VERSION é muito antiga. Requer 3.10 ou superior"
        exit 1
    fi

    echo "Requisitos do sistema atendidos!"
}

# Função para verificar se Docker está instalado
check_docker() {
    if command -v docker >/dev/null 2>&1; then
        echo "Docker já está instalado!"
        docker --version
        read -p "Deseja remover o Docker e fazer uma limpeza? (s/n): " remove_choice
        if [[ "$remove_choice" =~ ^[Ss]$ ]]; then
            remove_docker
        else
            echo "Mantendo a instalação existente do Docker."
            exit 0
        fi
    else
        echo "Docker não encontrado."
        read -p "Deseja instalar o Docker? (s/n): " install_choice
        if [[ "$install_choice" =~ ^[Ss]$ ]]; then
            check_internet
            install_docker
        else
            echo "Instalação cancelada pelo usuário."
            exit 0
        fi
    fi
}

# Função para remover Docker e fazer limpeza
remove_docker() {
    echo "Removendo Docker e limpando sistema..."

    # Para o serviço Docker
    sudo systemctl stop docker 2>>"$LOG_FILE" || echo "Aviso: Falha ao parar o serviço Docker, consulte $LOG_FILE"
    sudo systemctl disable docker 2>>"$LOG_FILE" || echo "Aviso: Falha ao desativar o serviço Docker"

    # Remove pacotes Docker
    sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo apt-get autoremove -y --purge
    sudo apt-get autoclean

    # Remove arquivos de configuração e dados
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/run/docker
    sudo rm -rf /var/lib/containerd
    sudo rm -rf /etc/docker
    sudo rm -f /etc/apt/sources.list.d/docker.list
    sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg

    # Remove grupo docker
    sudo groupdel docker 2>/dev/null

otton
    echo "Docker removido e sistema limpo!"
}

# Função para instalar Docker
install_docker() {
    echo "Atualizando pacotes do sistema..."
    sudo apt-get update || { echo "Erro: Falha ao atualizar pacotes"; exit 1; }

    echo "Instalando pacotes necessários..."
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release || { echo "Erro: Falha ao instalar dependências"; exit 1; }

    echo "Adicionando chave GPG oficial do Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || { echo "Erro: Falha ao adicionar chave GPG"; exit 1; }

    echo "Configurando repositório Docker..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo "Atualizando pacotes e instalando Docker..."
    sudo apt-get update || { echo "Erro: Falha ao atualizar pacotes"; exit 1; }
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || { echo "Erro: Falha ao instalar Docker"; exit 1; }

    # Verifica se a instalação foi bem-sucedida
    if command -v docker >/dev/null 2>&1; then
        echo "Docker instalado com sucesso!"
        docker --version
    else
        echo "Erro: Falha na instalação do Docker"
        exit 1
    fi

    configure_docker
}

# Função para configurar Docker
configure_docker() {
    echo "Configurando Docker..."

    # Adiciona usuário atual ao grupo docker
    sudo usermod -aG docker $USER

    # Inicia e habilita o serviço Docker
    sudo systemctl start docker || { echo "Erro: Falha ao iniciar o serviço Docker"; exit 1; }
    sudo systemctl enable docker || { echo "Erro: Falha ao habilitar o serviço Docker"; exit 1; }

    echo "Docker configurado com sucesso!"
    echo "Nota: Faça logout e login novamente ou execute 'newgrp docker' para usar o Docker sem sudo."
}

# Executa as funções
check_privileges
check_requirements
check_docker

echo "Processo concluído!"