# Script para configurar IP fixo no Windows Server 2022

# Define as variáveis
$InterfaceAlias = "Ethernet"  # Nome da interface de rede (ajuste se necessário)
$IPAddress = "192.168.2.107"  # Endereço IP desejado
$SubnetMask = "255.255.255.0" # Máscara de sub-rede
$Gateway = "192.168.2.1"      # Gateway padrão
$DNSServer = "8.8.8.8"        # Servidor DNS (Google DNS como exemplo, ajuste se necessário)

# Verifica se o script está sendo executado como administrador
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Este script precisa ser executado como administrador. Abra o PowerShell como administrador e tente novamente."
    Exit
}

# Obtém a interface de rede ativa
$Interface = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.Name -eq $InterfaceAlias}
if (-not $Interface) {
    Write-Host "Interface de rede '$InterfaceAlias' não encontrada ou não está ativa. Verifique o nome da interface com 'Get-NetAdapter'."
    Exit
}

# Remove configurações de IP automático (DHCP), se houver
Write-Host "Removendo configurações de DHCP, se existentes..."
Set-NetIPInterface -InterfaceAlias $InterfaceAlias -Dhcp Disabled

# Configura o endereço IP fixo
Write-Host "Configurando o IP $IPAddress..."
New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPAddress -PrefixLength 24 -DefaultGateway $Gateway -ErrorAction Stop | Out-Null

# Configura o servidor DNS
Write-Host "Configurando o servidor DNS..."
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $DNSServer

# Verifica se a configuração foi aplicada corretamente
$IPConfig = Get-NetIPAddress -InterfaceAlias $InterfaceAlias | Where-Object {$_.IPAddress -eq $IPAddress}
if ($IPConfig) {
    Write-Host "Configuração de IP fixo aplicada com sucesso!"
    Write-Host "IP: $IPAddress"
    Write-Host "Gateway: $Gateway"
    Write-Host "DNS: $DNSServer"
} else {
    Write-Host "Erro ao aplicar a configuração de IP. Verifique as configurações de rede."
    Exit
}

# Testa a conectividade com o gateway
Write-Host "Testando conectividade com o gateway $Gateway..."
if (Test-Connection -ComputerName $Gateway -Count 2 -Quiet) {
    Write-Host "Conexão com o gateway bem-sucedida!"
} else {
    Write-Host "Falha ao conectar ao gateway. Verifique a configuração ou a rede."
}

Write-Host "Script concluído."