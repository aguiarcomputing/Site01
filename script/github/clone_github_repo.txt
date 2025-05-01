#!/bin/bash

# Script para clonar um repositório do GitHub no Ubuntu Server

# Solicita o nome de usuário do GitHub
read -p "Digite seu nome de usuário do GitHub: " GITHUB_USER

# Solicita a senha ou token de acesso pessoal (máscara a entrada)
read -s -p "Digite sua senha ou token de acesso pessoal do GitHub: " GITHUB_TOKEN
echo ""

# Solicita a URL do repositório (ex: https://github.com/usuario/repositorio.git)
read -p "Digite a URL do repositório (ex: https://github.com/usuario/repositorio.git): " REPO_URL

# Verifica se a URL do repositório é válida
if [[ ! "$REPO_URL" =~ ^https://github.com/.*\.git$ ]]; then
    echo "Erro: URL do repositório inválida. Deve ser algo como https://github.com/usuario/repositorio.git"
    exit 1
fi

# Configura o Git para usar as credenciais fornecidas
# Insere o token na URL do repositório para autenticação
AUTH_URL=$(echo "$REPO_URL" | sed "s|https://|https://${GITHUB_USER}:${GITHUB_TOKEN}@|")

# Tenta clonar o repositório
echo "Clonando o repositório..."
if git clone "$AUTH_URL"; then
    echo "Repositório clonado com sucesso!"
else
    echo "Erro ao clonar o repositório. Verifique suas credenciais ou a URL do repositório."
    exit 1
fi

# Limpa as variáveis sensíveis
unset GITHUB_TOKEN
unset AUTH_URL

exit 0