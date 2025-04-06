#!/bin/bash

# Verifica se o usuário é "aguiar"
if [ "$(whoami)" != "aguiar" ]; then
    echo "Este script deve ser executado pelo usuário aguiar."
    exit 1
fi

# Atualiza a lista de pacotes disponíveis
echo "Atualizando a lista de pacotes..."
sudo apt update

# Atualiza os pacotes instalados para as versões mais recentes
echo "Atualizando os pacotes instalados..."
sudo apt upgrade -y

# Realiza uma atualização de distribuição para resolver dependências
echo "Realizando a atualização de distribuição..."
sudo apt dist-upgrade -y

# Remove pacotes desnecessários
echo "Removendo pacotes desnecessários..."
sudo apt autoremove -y

# Limpa o cache do APT
echo "Limpando o cache do APT..."
sudo apt clean

echo "Atualização concluída com sucesso!"
