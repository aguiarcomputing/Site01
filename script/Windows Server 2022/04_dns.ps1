# Script 3: Configuração do Servidor DNS - Windows Server 2022

# Verifica privilégios
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Execute este script como administrador!"
    Exit
}

# Instala o recurso DNS
Write-Host "Instalando o serviço DNS..."
Install-WindowsFeature -Name DNS -IncludeManagementTools

# Configura o DNS como servidor primário
Write-Host "Configurando o DNS..."
Add-DnsServerPrimaryZone -Name "dominio.local" -ZoneFile "aguiar.local.dns"  # Ajuste o nome do domínio
Add-DnsServerForwarder -IPAddress "8.8.8.8"  # Encaminhador DNS (Google DNS)

# Testa a configuração
Write-Host "Testando o servidor DNS..."
Resolve-DnsName -Name "google.com" -Server $IPAddress

Write-Host "Servidor DNS configurado com sucesso!"