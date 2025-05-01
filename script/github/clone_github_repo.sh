#!/bin/bash

# Script para clonar um repositório do GitHub no Ubuntu Server
# Nome de usuário e URL do repositório fixos
# Nome de usuário: leandro.aguiar@outlook.com
# URL do repositório: https://github.com/aguiarinformatica/DockerAguiarInformatica.git

# Define o nome de usuário do GitHub
GITHUB_USER="leandro.aguiar@outlook.com"

# Define a URL do repositório
REPO_URL="https://github.com/aguiarinformatica/DockerAguiarInformatica.git"

# Verifica se o Git está instalado
if ! command -v git &> /dev/null; then
    echo "Erro: Git não está instalado. Instale-o com 'sudo apt install git'."
    exit 1
fi

# Verifica se o curl está instalado (para validação de credenciais)
if ! command -v curl &> /dev/null; then
    echo "Erro: Curl não está instalado. Instale-o com 'sudo apt install curl'."
    exit 1
fi

# Solicita a senha ou token de acesso pessoal (máscara a entrada)
read -s -p "Digite seu token de acesso pessoal do GitHub: " GITHUB_TOKEN
echo ""

# Solicita o diretório de destino (opcional)
read -p "Digite o diretório de destino (deixe em branco para o diretório atual): " DEST_DIR
if [ -n "$DEST_DIR" ]; then
    if ! mkdir -p "$DEST_DIR" || ! cd "$DEST_DIR"; then
        echo "Erro: Não foi possível criar ou acessar o diretório $DEST_DIR."
        exit 1
    fi
fi

# Verifica as credenciais com a API do GitHub
if ! curl -s -u "$GITHUB_USER:$GITHUB_TOKEN" https://api.github.com/user >/dev/null; then
    echo "Erro: Credenciais inválidas. Verifique seu token de acesso pessoal."
    unset GITHUB_TOKEN
    exit 1
fi

# Configura as credenciais temporariamente
echo "protocol=https
host=github.com
username=$GITHUB_USER
password=$GITHUB_TOKEN" | git credential approve

# Tenta clonar o repositório
echo "Clonando o repositório $REPO_URL..."
ERROR=$(timeout 30 git clone "$REPO_URL" 2>&1)
if [ $? -eq 0 ]; then
    echo "Repositório clonado com sucesso!"
else
    echo "Erro ao clonar o repositório: $ERROR"
    git credential reject <<EOF
    protocol=https
    host=github.com
    EOF
    unset GITHUB_TOKEN
    exit 1
fi

# Limpa as credenciais
git credential reject <<EOF
protocol=https
host=github.com
EOF

# Limpa as variáveis sensíveis
unset GITHUB_TOKEN
unset GITHUB_USER
unset REPO_URL
unset DEST_DIR

exit 0