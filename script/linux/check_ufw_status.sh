#!/bin/bash

# Script para verificar o status do UFW e listar regras habilitadas

# Verifica se o script está sendo executado como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script precisa ser executado como root (use sudo)"
   exit 1
fi

# Verifica se o UFW está instalado
if ! command -v ufw &> /dev/null; then
    echo "UFW não está instalado. Instale com: sudo apt install ufw"
    exit 1
fi

# Verifica o status do UFW
echo "===== Status do Firewall (UFW) ====="
ufw_status=$(ufw status)
if [[ $ufw_status == *"Status: active"* ]]; then
    echo "O firewall está ATIVADO"
else
    echo "O firewall está DESATIVADO"
fi

# Lista as regras habilitadas
echo -e "\n===== Regras Habilitadas ====="
ufw status numbered

# Lista informações detalhadas (verbose)
echo -e "\n===== Informações Detalhadas ====="
ufw status verbose

# Verifica portas abertas (opcional, usando netstat ou ss)
echo -e "\n===== Portas Abertas no Sistema ====="
if command -v ss &> /dev/null; then
    ss -tuln
else
    netstat -tuln
fi

# Sugestões básicas de segurança
echo -e "\n===== Sugestões de Segurança ====="
echo "1. Certifique-se de que apenas as portas necessárias estão abertas."
echo "2. Considere limitar o acesso SSH (porta 22) a IPs específicos."
echo "3. Habilite o logging do UFW: sudo ufw logging on"
echo "4. Faça backup das regras: sudo ufw status > ufw_rules_backup.txt"