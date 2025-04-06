#!/bin/bash

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Use sudo."
  exit 1
fi

# Instala o UFW se não estiver presente
if ! command -v ufw &> /dev/null; then
  echo "UFW não encontrado. Instalando..."
  apt update
  apt install -y ufw
fi

# Verifica o status do firewall
echo "Verificando status do firewall..."
ufw status verbose

# Lista regras existentes
echo "Regras atuais do firewall:"
ufw status numbered

# Verifica se há regras de bloqueio explícitas
echo "Procurando por regras de bloqueio (DENY)..."
ufw status | grep -i "DENY" || echo "Nenhuma regra de bloqueio (DENY) encontrada."

# Libera a porta 2222 para SSH
echo "Liberando porta 2222 para SSH..."
ufw allow 2222/tcp
echo "Porta 2222 liberada."

# Libera a porta 9090 para Cockpit
echo "Liberando porta 9090 para Cockpit..."
ufw allow 9090/tcp
echo "Porta 9090 liberada."

# Garante que o UFW esteja ativado
echo "Ativando o firewall (se ainda não estiver ativo)..."
ufw --force enable

# Exibe o status final do firewall
echo "Status final do firewall:"
ufw status verbose

echo "Configuração concluída!"
echo " - Porta 2222 (SSH) e 9090 (Cockpit) liberadas."
echo "Teste o acesso SSH com: ssh aguiar@192.168.2.129 -p 2222"
echo "Teste o Cockpit acessando: http://192.168.2.129:9090 no navegador."
