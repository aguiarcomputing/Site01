#!/bin/bash

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Use sudo."
  exit 1
fi

# Atualiza o sistema
echo "Atualizando o sistema..."
apt update && apt upgrade -y

# Instala pacotes essenciais
apt install -y ufw fail2ban unattended-upgrades

# Cria o usuário 'aguiaradm' com a senha 'sysdm.cpl'
echo "Criando usuário 'aguiaradm'..."
adduser --disabled-password --gecos "" aguiaradm
echo "aguiaradm:sysdm.cpl" | chpasswd
usermod -aG sudo aguiaradm

# Configura o SSH na porta 2222
echo "Configurando SSH na porta 2222..."
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Reinicia o serviço SSH
systemctl restart sshd

# Configura o firewall com UFW
echo "Configurando firewall..."
ufw allow 2222/tcp
ufw enable
ufw status

# Configura atualizações automáticas
echo "Configurando atualizações automáticas..."
cat <<EOF > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

dpkg-reconfigure --priority=low unattended-upgrades

# Configura Fail2ban para proteção contra ataques de força bruta
echo "Configurando Fail2ban..."
cat <<EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
EOF

systemctl restart fail2ban

# Remove pacotes desnecessários e limpa o sistema
apt autoremove -y
apt autoclean

echo "Configuração concluída!"
echo " - Usuário 'aguiaradm' criado com senha 'sysdm.cpl'"
echo " - SSH configurado na porta 2222"
echo " - Firewall ativo com UFW"
echo " - Atualizações automáticas habilitadas"
echo " - Fail2ban configurado para proteger o SSH"
echo "Teste o acesso SSH com: ssh aguiaradm@<192.168.2.129> -p 2222"
