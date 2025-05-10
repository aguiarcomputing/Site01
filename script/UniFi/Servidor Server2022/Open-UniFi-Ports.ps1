# Script para abrir portas necessárias para o UniFi Network Server no Firewall do Windows

# Lista de portas TCP e UDP necessárias
$tcpPorts = @(8080, 8443, 8843)
$udpPorts = @(10001, 3478)

# Função para verificar se uma regra já existe
function Test-FirewallRule {
    param (
        [string]$DisplayName,
        [string]$Direction,
        [string]$Protocol,
        [string]$LocalPort
    )
    $rule = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue
    if ($rule) {
        Write-Host "Regra para $DisplayName ($Protocol $LocalPort) já existe."
        return $true
    }
    return $false
}

# Habilitar execução do script como administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Este script precisa ser executado como administrador. Iniciando com elevação..."
    Start-Process powershell -Verb runAs -ArgumentList "-File `"$PSCommandPath`""
    exit
}

# Criar regras para portas TCP
foreach ($port in $tcpPorts) {
    $ruleName = "UniFi-TCP-$port-Inbound"
    if (-not (Test-FirewallRule -DisplayName $ruleName -Direction "Inbound" -Protocol "TCP" -LocalPort $port)) {
        New-NetFirewallRule -DisplayName $ruleName `
                            -Direction Inbound `
                            -Protocol TCP `
                            -LocalPort $port `
                            -Action Allow `
                            -Profile Any
        Write-Host "Regra criada para TCP $port (Inbound)."
    }
}

# Criar regras para portas UDP
foreach ($port in $udpPorts) {
    $ruleName = "UniFi-UDP-$port-Inbound"
    if (-not (Test-FirewallRule -DisplayName $ruleName -Direction "Inbound" -Protocol "UDP" -LocalPort $port)) {
        New-NetFirewallRule -DisplayName $ruleName `
                            -Direction Inbound `
                            -Protocol UDP `
                            -LocalPort $port `
                            -Action Allow `
                            -Profile Any
        Write-Host "Regra criada para UDP $port (Inbound)."
    }
}

Write-Host "Configuração das portas do firewall concluída."