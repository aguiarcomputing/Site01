#!/bin/bash

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Este script precisa ser configurado como root. Use sudo."
  exit 1
fi

# Instala dependências, se necessário
apt update
apt install -y mailutils

# Configurações de e-mail
EMAIL_DESTINO="suporte@aguiarinformatica.com.br"  # Substitua pelo e-mail de destino
EMAIL_REMETENTE="dinhorex@gmail.com"   # Substitua pelo e-mail remetente
SMTP_SERVER="smtp.gmail.com:587"       # Exemplo: Gmail SMTP
SMTP_USER="dinhorex@gmail.com"         # Substitua pelo seu e-mail
SMTP_PASS="lfsp ctdz fksv nqql"        # Substitua pela senha ou senha de app (se usar 2FA)

# Arquivo de log temporário
LOG_TEMP="/tmp/login_notify.log"

# Função para enviar e-mail
enviar_email() {
  local usuario="$1"
  local ip="$2"
  local data=$(date '+%Y-%m-%d %H:%M:%S')
  local assunto="Alerta: Login detectado no servidor - Usuário: $aguiar"
  local corpo="Um login foi detectado no servidor:\n\nUsuário: $aguiar\nIP: $ip\nData: $data\n\nVerifique se esta atividade é autorizada."

  echo -e "$corpo" | mail -s "$assunto" \
    -r "$EMAIL_REMETENTE" \
    -S smtp="$SMTP_SERVER" \
    -S smtp-auth=login \
    -S smtp-auth-user="$SMTP_USER" \
    -S smtp-auth-password="$SMTP_PASS" \
    "$EMAIL_DESTINO"
}

# Monitora logins via SSH
echo "Configurando monitoramento de logins..."
cat << 'EOF' > /usr/local/bin/monitor_login.sh
#!/bin/bash
# Script chamado por SSH ou login local
USUARIO=$(whoami)
IP=$(echo $SSH_CONNECTION | awk '{print $1}')
if [ -n "$IP" ]; then
  # Login via SSH
  bash /usr/local/bin/enviar_notificacao.sh "$USUARIO" "$IP" &
else
  # Login local (se aplicável)
  IP="Local"
  bash /usr/local/bin/enviar_notificacao.sh "$USUARIO" "$IP" &
fi
EOF

# Script de notificação
cat << EOF > /usr/local/bin/enviar_notificacao.sh
#!/bin/bash
USUARIO="\$1"
IP="\$2"
echo "Enviando notificação para login de \$USUARIO de \$IP..." > $LOG_TEMP
bash -c "enviar_email '\$USUARIO' '\$IP'" >> $LOG_TEMP 2>&1
EOF

# Dá permissões aos scripts
chmod +x /usr/local/bin/monitor_login.sh
chmod +x /usr/local/bin/enviar_notificacao.sh

# Adiciona ao .bashrc de root para logins interativos
echo "Adicionando ao .bashrc do root..."
echo "[ -n \"\$SSH_CONNECTION\" ] && /usr/local/bin/monitor_login.sh" >> /root/.bashrc

# Adiciona para outros usuários (opcional, para todos os usuários existentes)
for user in $(getent passwd | grep -v nologin | grep -v false | cut -d: -f1); do
  if [ "$user" != "root" ]; then
    echo "Adicionando ao .bashrc do usuário $user..."
    echo "[ -n \"\$SSH_CONNECTION\" ] && /usr/local/bin/monitor_login.sh" >> /home/$user/.bashrc 2>/dev/null || true
  fi
done

# Configura o Postfix para usar SMTP externo (exemplo com Gmail)
echo "Configurando Postfix para envio de e-mails..."
cat << EOF > /etc/postfix/main.cf
relayhost = $SMTP_SERVER
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
EOF

# Configura credenciais SMTP
cat << EOF > /etc/postfix/sasl_passwd
$SMTP_SERVER $SMTP_USER:$SMTP_PASS
EOF

# Protege e aplica as configurações do Postfix
postmap /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd
systemctl restart postfix

echo "Configuração concluída!"
echo " - Monitoramento de logins habilitado para root e outros usuários."
echo " - E-mails serão enviados para $EMAIL_DESTINO em caso de login."
echo "Teste fazendo login via SSH ou localmente."
