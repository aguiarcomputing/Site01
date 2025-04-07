#!/bin/bash

# Verifica se o usuário é "aguiar"
if [ "$(whoami)" != "aguiar" ]; then
    echo "Este script deve ser executado pelo usuário aguiar."
    exit 1
fi

# Atualiza a lista de pacotes disponíveis
echo "Atualizando a lista de pacotes..."
sudo apt update

# Instala o Cockpit
echo "Instalando o Cockpit..."
sudo apt install cockpit -y

# Inicia e habilita o serviço do Cockpit
echo "Iniciando e habilitando o serviço do Cockpit..."
sudo systemctl start cockpit
sudo systemctl enable cockpit

echo "Instalação do Cockpit concluída com sucesso!"
echo "Acesse o Cockpit em http://192.168.2.126:9090"
