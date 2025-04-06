#!/bin/bash

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Use sudo."
  exit 1
fi

# Define variáveis
LOG_DIR="/var/log"
BACKUP_DIR="/var/log/backup_$(date +%Y%m%d_%H%M%S)"
TEMP_DIR="/tmp"

# Cria um diretório de backup para os logs
echo "Criando backup dos logs em $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"
cp -r $LOG_DIR/*.log "$BACKUP_DIR" 2>/dev/null

# Atualiza o sistema e remove pacotes desnecessários
echo "Atualizando o sistema e removendo pacotes desnecessários..."
apt update
apt upgrade -y
apt autoremove -y
apt autoclean

# Limpa arquivos temporários
echo "Limpando arquivos temporários em $TEMP_DIR..."
rm -rf $TEMP_DIR/* 2>/dev/null
rm -rf $TEMP_DIR/.* 2>/dev/null

# Limpa logs antigos
echo "Limpando logs em $LOG_DIR..."
find $LOG_DIR -type f -name "*.log" -exec truncate -s 0 {} \;
find $LOG_DIR -type f -name "*.log.*" -mtime +7 -exec rm -f {} \; # Remove logs comprimidos com mais de 7 dias
find $LOG_DIR -type f -name "*.gz" -mtime +7 -exec rm -f {} \;    # Remove arquivos .gz com mais de 7 dias

# Limpa o cache do APT
echo "Limpando cache do APT..."
rm -rf /var/cache/apt/archives/*.deb
rm -rf /var/cache/apt/archives/partial/*.deb

# (Opcional) Remove arquivos órfãos - descomente se desejar
# echo "Removendo arquivos órfãos (pacotes não mais necessários)..."
# apt install -y deborphan
# deborphan | xargs apt remove -y --purge

# (Opcional) Limpa o journalctl - descomente e ajuste o tamanho se desejar
# echo "Limpando logs do journalctl (mantendo apenas 50MB)..."
# journalctl --vacuum-size=50M

# Verifica o espaço liberado
echo "Verificando espaço em disco antes e depois da limpeza..."
df -h / | grep -v "Filesystem" > /tmp/df_before
sleep 1
df -h / | grep -v "Filesystem" > /tmp/df_after
echo "Antes da limpeza:"
cat /tmp/df_before
echo "Depois da limpeza:"
cat /tmp/df_after
rm /tmp/df_before /tmp/df_after

echo "Limpeza concluída!"
echo " - Pacotes desnecessários removidos."
echo " - Arquivos temporários limpos em $TEMP_DIR."
echo " - Logs em $LOG_DIR truncados e backups salvos em $BACKUP_DIR."
echo " - Cache do APT limpo."
