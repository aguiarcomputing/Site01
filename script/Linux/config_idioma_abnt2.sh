#!/bin/bash

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Use sudo."
  exit 1
fi

# Atualiza os pacotes e instala locales, caso necessário
echo "Atualizando pacotes e instalando locales..."
apt update
apt install -y locales

# Gera o locale para Português do Brasil
echo "Configurando locale para pt_BR.UTF-8..."
locale-gen pt_BR.UTF-8

# Define o locale padrão
update-locale LANG=pt_BR.UTF-8 LC_ALL=pt_BR.UTF-8

# Reconfigura os pacotes de locale
echo "Reconfigurando locales..."
dpkg-reconfigure -f noninteractive locales

# Configura o layout do teclado para ABNT2
echo "Configurando teclado para ABNT2..."
cat <<EOF > /etc/default/keyboard
XKBMODEL="pc105"
XKBLAYOUT="br"
XKBVARIANT="abnt2"
XKBOPTIONS=""
EOF

# Aplica as configurações de teclado
setupcon

# Carrega o layout do teclado imediatamente no console
loadkeys br-abnt2

echo "Configuração concluída!"
echo " - Idioma configurado para Português do Brasil (pt_BR.UTF-8)"
echo " - Teclado configurado para ABNT2"
echo "Reinicie o sistema ou o terminal para garantir que as mudanças sejam aplicadas."

