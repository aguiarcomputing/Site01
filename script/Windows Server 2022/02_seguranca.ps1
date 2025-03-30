# Script 1: Configuração Básica e Segurança - Windows Server 2022

# Verifica se está sendo executado como administrador
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Execute este script como administrador!"
    Exit
}

# Variáveis
$NewServerName = "srv-dc-01"
$IPAddress = "192.168.2.107"
$SubnetMask = "255.255.255.0"  # /24
$Gateway = "192.168.2.1"
$DNS = "192.168.2.107"  # O próprio servidor será DNS após configuração
$AdminPassword = "bz07fx$#oela14"

# Renomeia o servidor
Write-Host "Renomeando o servidor para $NewServerName..."
Rename-Computer -NewName $NewServerName -Force -Restart:$false

# Configura IP fixo
Write-Host "Configurando IP fixo $IPAddress..."
$Interface = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
New-NetIPAddress -InterfaceAlias $Interface.Name -IPAddress $IPAddress -PrefixLength 24 -DefaultGateway $Gateway -ErrorAction Stop | Out-Null
Set-DnsClientServerAddress -InterfaceAlias $Interface.Name -ServerAddresses $DNS

# Atualiza a senha do administrador local
Write-Host "Atualizando senha do administrador..."
$AdminUser = [ADSI]"WinNT://./Administrador,User"
$AdminUser.SetPassword($AdminPassword)
$AdminUser.SetInfo()

# Configurações de segurança básicas
Write-Host "Aplicando configurações de segurança..."
# Desativa SMBv1 (vulnerável)
Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart
# Habilita firewall e bloqueia portas desnecessárias
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
# Desativa acesso remoto ao Registro
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurePipeServers\winreg" -Name "RemoteRegAccess" -Value 0

# Instala atualizações do Windows
Write-Host "Instalando atualizações do Windows..."
Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
Import-Module PSWindowsUpdate
Get-WindowsUpdate -Install -AcceptAll -AutoReboot

Write-Host "Configuração básica e segurança concluída. Reinicie o servidor manualmente após verificar."