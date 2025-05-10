#!/bin/bash

# Verifica se o ufw está instalado, caso contrário, instala
if ! command -v ufw >/dev/null; then
    echo "Instalando ufw..."
    apt update
    apt install ufw -y
fi

# Garante que a porta 2222 está liberada para SSH
echo "Liberando porta 2222 para SSH..."
ufw allow 2222/tcp

# Bloqueia a porta 22
echo "Bloqueando porta 22..."
ufw deny 22/tcp

# Ativa o ufw (se ainda não estiver ativo)
ufw --force enable

# Recarrega o ufw para aplicar as alterações
ufw reload

# Exibe o status do ufw para verificação
echo "Status do firewall:"
ufw status

echo "Porta 22 bloqueada e porta 2222 liberada para SSH."