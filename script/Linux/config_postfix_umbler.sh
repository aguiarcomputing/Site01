#!/bin/bash

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Use sudo."
  exit 1
fi

# Instala Postfix e mailutils
echo "Instalando Postfix e mailutils..."
apt update
apt install -y postfix mailutils

# Configurações da Umbler
SMTP_SERVER="smtp.umbler.com:587"
EMAIL="suporte@aguiarinformatica.com.br"
echo "Por favor, insira a senha do e-mail $EMAIL (fornecida pela Umbler):"
read -s SMTP_PASS  # Lê a senha sem exibi-la no terminal

# Configura o arquivo main.cf do Postfix
echo "Configurando Postfix..."
cat << EOF > /etc/postfix/main.cf
# Configuração básica
myhostname = $(hostname)
mydomain = localdomain
myorigin = \$myhostname
inet_interfaces = all
inet_protocols = all

# Configuração do relay SMTP (Umbler)
relayhost = $SMTP_SERVER
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
EOF

# Cria o arquivo de credenciais
echo "Criando arquivo de credenciais SMTP..."
cat << EOF > /etc/postfix/sasl_passwd
$SMTP_SERVER $EMAIL:$SMTP_PASS
EOF

# Protege e converte o arquivo de credenciais
postmap /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd
chown root:root /etc/postfix/sasl_passwd

# Reinicia o Postfix
echo "Reiniciando o Postfix..."
systemctl restart postfix

# Testa o envio de e-mail
echo "Testando envio de e-mail..."
echo "Este é um teste de envio de e-mail do servidor." | mail -s "Teste Postfix" -r "$EMAIL" "$EMAIL"

echo "Configuração concluída!"
echo " - Postfix configurado para usar $EMAIL via Umbler SMTP."
echo " - Verifique sua caixa de entrada (e spam) em $EMAIL para o e-mail de teste."
echo "Se não receber, confira os logs em /var/log/mail.log para erros."
