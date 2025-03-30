# Script 3: Configuração do Servidor DNS - Windows Server 2022 (Ajustado)

# Verifica privilégios
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Execute este script como administrador!"
    Exit
}

# Variáveis
$IPAddress = "192.168.2.107"  # Endereço IP do servidor
$DomainName = "aguiar.local"  # Nome do domínio (ajuste conforme necessário)

# Instala o recurso DNS
Write-Host "Instalando o serviço DNS..."
Install-WindowsFeature -Name DNS -IncludeManagementTools

# Configura o servidor como DNS primário
Write-Host "Configurando o servidor como DNS primário..."
$Interface = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
Set-DnsClientServerAddress -InterfaceAlias $Interface.Name -ServerAddresses $IPAddress

# Cria uma zona primária no DNS
Write-Host "Criando zona primária para $DomainName..."
Add-DnsServerPrimaryZone -Name $DomainName -ZoneFile "$DomainName.dns"

# Configura o servidor como o DNS primário da zona
Write-Host "Definindo $IPAddress como DNS primário da zona $DomainName..."
Add-DnsServerResourceRecordA -Name "@" -ZoneName $DomainName -IPv4Address $IPAddress -TimeToLive 01:00:00

# Configura um encaminhador (opcional) para consultas externas
Write-Host "Configurando encaminhador DNS (Google DNS como exemplo)..."
Add-DnsServerForwarder -IPAddress "8.8.8.8"  # Ajuste ou remova se não for necessário

# Testa a configuração
Write-Host "Testando o servidor DNS..."
$TestResult = Resolve-DnsName -Name "google.com" -Server $IPAddress -ErrorAction SilentlyContinue
if ($TestResult) {
    Write-Host "Servidor DNS funcionando corretamente!"
} else {
    Write-Host "Falha ao resolver nomes. Verifique a configuração."
}

Write-Host "Servidor DNS primário configurado com sucesso!"