#!/bin/bash

# Verifica se o Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "Docker não está instalado no sistema."
    exit 1
fi

echo "Docker está instalado."

# Verifica se o serviço do Docker está ativo
if systemctl is-active --quiet docker; then
    echo "O serviço do Docker está ativo."
else
    echo "O serviço do Docker não está ativo."
fi

# Verifica se o serviço do Docker está habilitado para iniciar automaticamente
if systemctl is-enabled --quiet docker; then
    echo "O serviço do Docker está habilitado para iniciar automaticamente com o sistema."
else
    echo "O serviço do Docker não está habilitado para iniciar automaticamente com o sistema."
fi

# Exibe a versão do Docker instalada
docker_version=$(docker --version)
echo "Versão do Docker: $docker_version"