#!/bin/bash

# Atualiza o sistema
apt update && apt upgrade -y

# Verifica se o OpenSSH Server está instalado, caso contrário, instala
if ! dpkg -l | grep -q openssh-server; then
    echo "Instalando OpenSSH Server..."
    apt install openssh-server -y
else
    echo "OpenSSH Server já está instalado."
fi

# Verifica se o net-tools está instalado, caso contrário, instala
if ! dpkg -l | grep -q net-tools; then
    echo "Instalando net-tools..."
    apt install net-tools -y
else
    echo "net-tools já está instalado."
fi

# Habilita e inicia o serviço SSH
systemctl enable ssh
systemctl start ssh

# Configura a porta SSH para 2222
echo "Configurando SSH para usar a porta 2222..."
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config

# Abre a porta 2222 no firewall (se o ufw estiver instalado)
if command -v ufw >/dev/null; then
    ufw allow 2222/tcp
    ufw reload
fi

# Cria o usuário 'aguiar' com privilégios de administrador
if ! id "aguiar" >/dev/null 2>&1; then
    echo "Criando usuário 'aguiar'..."
    adduser --gecos "" aguiar
    usermod -aG sudo aguiar
    echo "Usuário 'aguiar' criado e adicionado ao grupo sudo."
else
    echo "Usuário 'aguiar' já existe."
    # Garante que o usuário tenha privilégios de administrador
    usermod -aG sudo aguiar
fi

# Configura acesso SSH para o usuário 'aguiar'
mkdir -p /home/aguiar/.ssh
chmod 700 /home/aguiar/.ssh
chown aguiar:aguiar /home/aguiar/.ssh

# Reinicia o serviço SSH para aplicar as alterações
systemctl restart ssh

echo "Configuração concluída!"
echo "SSH configurado na porta 2222, usuário 'aguiar' criado com privilégios de administrador."