#!/bin/bash

# Script para configurar um servidor Docker com boas práticas de segurança
# Configura nginx com IP 192.168.2.222 e porta 8080
# Inclui abertura automática de página para testar contêiner nginx
# Requer privilégios de root para executar
# Compatível com sistemas baseados em Ubuntu/Debian

# Variáveis
LOG_FILE="/var/log/docker_setup.log"
DOCKER_CONF="/etc/docker/daemon.json"
USER_DOCKER="dockeruser"
GROUP_DOCKER="docker"
NGINX_IP="192.168.2.222"
NGINX_PORT="8080"
TEST_URL="http://$NGINX_IP:$NGINX_PORT"

# Função para escrever logs
write_log() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

# Função para verificar erros
check_error() {
    if [ $? -ne 0 ]; then
        write_log "ERRO: $1"
        exit 1
    fi
}

# Função para testar conectividade com o contêiner
test_nginx() {
    write_log "Testando conectividade com $TEST_URL"
    if curl --silent --fail "$TEST_URL" > /dev/null; then
        write_log "Conexão com nginx bem-sucedida"
        return 0
    else
        write_log "ERRO: Falha ao conectar ao nginx em $TEST_URL"
        return 1
    fi
}

# Início do script
write_log "Iniciando configuração segura do Docker"

# 1. Verificar privilégios de root
if [ "$EUID" -ne 0 ]; then
    write_log "Este script deve ser executado como root"
    exit 1
fi

# 2. Criar diretório de logs, se não existir
mkdir -p /var/log
check_error "Falha ao criar diretório de logs"

# 3. Verificar se o IP está configurado no host
if ! ip addr show | grep -q "$NGINX_IP"; then
    write_log "Aviso: IP $NGINX_IP não encontrado nas interfaces de rede. Configure o IP antes de prosseguir."
fi

# 4. Instalar Docker, se não estiver instalado
if ! command -v docker &> /dev/null; then
    write_log "Docker não encontrado. Instalando..."
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    check_error "Falha ao instalar pré-requisitos"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    check_error "Falha ao instalar Docker"
else
    write_log "Docker já instalado"
fi

# 5. Instalar xdg-utils para xdg-open, se necessário
if ! command -v xdg-open &> /dev/null; then
    write_log "Instalando xdg-utils"
    apt-get install -y xdg-utils
    check_error "Falha ao instalar xdg-utils"
fi

# 6. Criar usuário não-root para gerenciar Docker
if ! id "$USER_DOCKER" &> /dev/null; then
    write_log "Criando usuário $USER_DOCKER"
    useradd -m -s /bin/bash "$USER_DOCKER"
    check_error "Falha ao criar usuário $USER_DOCKER"
fi

# 7. Adicionar usuário ao grupo docker
if ! getent group "$GROUP_DOCKER" &> /dev/null; then
    groupadd "$GROUP_DOCKER"
fi
usermod -aG "$GROUP_DOCKER" "$USER_DOCKER"
check_error "Falha ao adicionar usuário ao grupo docker"

# 8. Proteger o soquete do Docker
write_log "Configurando permissões do soquete do Docker"
chown root:"$GROUP_DOCKER" /var/run/docker.sock
chmod 660 /var/run/docker.sock
check_error "Falha ao configurar permissões do soquete"

# 9. Configurar daemon.json com opções seguras
write_log "Configurando /etc/docker/daemon.json"
mkdir -p /etc/docker
cat > "$DOCKER_CONF" << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "icc": false,
  "userns-remap": "default",
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true
}
EOF
check_error "Falha ao configurar daemon.json"

# 10. Reiniciar serviço Docker
write_log "Reiniciando serviço Docker"
systemctl restart docker
check_error "Falha ao reiniciar Docker"
systemctl enable docker
write_log "Docker configurado para iniciar automaticamente"

# 11. Configurar UFW (firewall)
if ! command -v ufw &> /dev/null; then
    write_log "Instalando UFW"
    apt-get install -y ufw
    check_error "Falha ao instalar UFW"
fi

write_log "Configurando regras do firewall"
ufw default deny incoming
ufw default allow outgoing
ufw allow to "$NGINX_IP" port "$NGINX_PORT" proto tcp
ufw allow 22/tcp  # SSH
ufw --force enable
check_error "Falha ao configurar UFW"
write_log "Firewall configurado com sucesso"

# 12. Criar contêiner de teste seguro (nginx)
write_log "Criando contêiner de teste seguro com nginx"
docker pull nginx:latest
check_error "Falha ao baixar imagem nginx"

docker run -d \
  --name secure-nginx \
  -p "$NGINX_IP:$NGINX_PORT:80" \
  --read-only \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  --restart=unless-stopped \
  nginx:latest
check_error "Falha ao criar contêiner nginx"
write_log "Contêiner nginx criado e rodando em $NGINX_IP:$NGINX_PORT"

# 13. Verificar status do contêiner
if docker ps | grep -q secure-nginx; then
    write_log "Contêiner secure-nginx está rodando"
else
    write_log "ERRO: Contêiner secure-nginx não está rodando"
    exit 1
fi

# 14. Testar e abrir página no navegador
if test_nginx; then
    write_log "Abrindo $TEST_URL no navegador"
    xdg-open "$TEST_URL" &
    check_error "Falha ao abrir navegador"
else
    write_log "Não foi possível abrir o navegador devido a falha na conexão"
    exit 1
fi

# 15. Finalizar
write_log "Configuração segura do Docker concluída com sucesso"
write_log "Acesse o nginx em $TEST_URL"
write_log "Use o usuário $USER_DOCKER para gerenciar o Docker"

exit 0