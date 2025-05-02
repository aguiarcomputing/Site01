#!/bin/bash

# Script para listar portas abertas, serviços e verificar riscos de segurança em um servidor Ubuntu
# Requer privilégios de superusuário para algumas operações

# Função para verificar e instalar dependências
install_dependencies() {
    local deps=("netstat" "lsof" "nmap")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "$dep não encontrado. Instalando..."
            sudo apt-get update
            sudo apt-get install -y "${dep%-*}" || {
                echo "Falha ao instalar $dep. Verifique sua conexão ou permissões."
                exit 1
            }
        fi
    done
}

# Função para verificar permissões de root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Este script precisa ser executado como root (sudo)."
        exit 1
    fi
}

# Função para listar portas abertas com netstat e lsof
list_open_ports() {
    echo "Listando portas abertas, IPs, processos e serviços..."
    echo "---------------------------------------------------"

    netstat -tulnp 2>/dev/null | grep LISTEN | while read -r line; do
        proto=$(echo "$line" | awk '{print $1}')
        ip_port=$(echo "$line" | awk '{print $4}')
        pid=$(echo "$line" | awk '{print $7}' | cut -d'/' -f1)

        ip=$(echo "$ip_port" | cut -d':' -f1)
        port=$(echo "$ip_port" | cut -d':' -f2)

        if [ -n "$pid" ]; then
            process_name=$(lsof -p "$pid" -a -i 4,6 -F n | grep -v "lsof" | head -n 1 | awk '{print $1}' || echo "Desconhecido")
        else
            process_name="Desconhecido"
        fi

        echo "Protocolo: $proto | IP: $ip | Porta: $port | PID: $pid | Processo: $process_name"
    done
    echo "---------------------------------------------------"
}

# Função para varredura profunda com nmap
nmap_deep_scan() {
    local output_file="/tmp/nmap_scan_$(date +%F_%H-%M-%S).txt"
    echo "Executando varredura profunda com nmap... (Resultados salvos em $output_file)"
    echo "---------------------------------------------------"

    # Varredura com detecção de versão, sistema operacional e scripts de vulnerabilidade
    nmap -sV -sC -O -p- --open localhost -oN "$output_file" > /dev/null

    # Exibe portas abertas, serviços e versões
    echo "Portas abertas e serviços detectados pelo nmap:"
    grep "open" "$output_file" | while read -r line; do
        port_service=$(echo "$line" | awk '{print $1, $2, $3}')
        echo "$port_service"
    done
    echo "---------------------------------------------------"

    # Identifica riscos potenciais
    echo "Verificando serviços potencialmente arriscados..."
    check_security_risks "$output_file"
}

# Função para verificar riscos de segurança
check_security_risks() {
    local nmap_output="$1"
    local risky_services=("telnet" "ftp" "smb" "rdp" "mysql" "postgresql" "vnc" "http" "ssh")
    local warnings=()

    # Verifica serviços conhecidos por vulnerabilidades
    for service in "${risky_services[@]}"; do
        if grep -i "$service" "$nmap_output" > /dev/null; then
            warnings+=("Serviço $service detectado. Verifique se está atualizado e configurado corretamente.")
        fi
    done

    # Verifica versões desatualizadas ou vulneráveis
    if grep -i "Apache/2.4.[0-29]" "$nmap_output" > /dev/null; then
        warnings+=("Versão antiga do Apache detectada. Atualize para a versão mais recente.")
    fi
    if grep -i "OpenSSH.*[0-6]\." "$nmap_output" > /dev/null; then
        warnings+=("Versão antiga do OpenSSH detectada. Atualize para a versão mais recente.")
    fi

    # Exibe avisos
    if [ ${#warnings[@]} -eq 0 ]; then
        echo "Nenhum risco crítico identificado."
    else
        echo "AVISOS DE SEGURANÇA:"
        for warning in "${warnings[@]}"; do
            echo "- $warning"
        done
        echo "Recomendações: Atualize os serviços listados, restrinja acesso desnecessário e revise configurações de firewall."
    fi
    echo "---------------------------------------------------"
}

# Função para registrar atividades em log
log_activity() {
    local log_file="/var/log/port_scan_$(date +%F).log"
    echo "[$(date)] Executando varredura de portas e serviços..." >> "$log_file"
    echo "[$(date)] Resultados do netstat:" >> "$log_file"
    netstat -tulnp 2>/dev/null | grep LISTEN >> "$log_file"
    echo "[$(date)] Varredura nmap concluída. Resultados em /tmp/nmap_scan_*.txt" >> "$log_file"
}

# Main
check_root
install_dependencies
list_open_ports
nmap_deep_scan
log_activity

echo "Varredura concluída. Verifique os logs em /var/log/port_scan_$(date +%F).log para auditoria."