# Script para configuração inicial do servidor de arquivos SRV-DC-01.empresa.local
# Requisitos: Windows Server 2022, executado como administrador

# 1. Atualizar o sistema
Write-Host "Instalando atualizações do Windows..."
Install-WindowsUpdate -AcceptAll -AutoReboot

# 2. Configurar hostname (já deve ser SRV-DC-01.empresa.local, mas garantimos)
$hostname = "SRV-DC-01.empresa.local"
if ($env:COMPUTERNAME -ne $hostname) {
    Rename-Computer -NewName $hostname -Force
    Write-Host "Hostname alterado para $hostname. Reiniciando..."
    Restart-Computer -Force
}

# 3. Configurar IP estático
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
New-NetIPAddress -InterfaceAlias $interface.Name -IPAddress "192.168.2.200" -PrefixLength 24 -DefaultGateway "192.168.2.1" -Force
Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses ("192.168.2.10", "8.8.8.8")

# 4. Hardening: Desativar serviços desnecessários
$servicesToDisable = @("Telnet", "SNMP", "FTP", "Xbox*")
foreach ($service in $servicesToDisable) {
    Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "Serviço $service desativado."
}

# 5. Hardening: Configurar políticas de senha via GPO
Write-Host "Configurando políticas de senha..."
secedit /export /cfg C:\temp\secpol.cfg
(Get-Content C:\temp\secpol.cfg) -replace "PasswordComplexity = 0", "PasswordComplexity = 1" | Set-Content C:\temp\secpol.cfg
(Get-Content C:\temp\secpol.cfg) -replace "MinimumPasswordLength = 7", "MinimumPasswordLength = 12" | Set-Content C:\temp\secpol.cfg
(Get-Content C:\temp\secpol.cfg) -replace "MaximumPasswordAge = 42", "MaximumPasswordAge = 90" | Set-Content C:\temp\secpol.cfg
secedit /configure /db C:\Windows\security\database\secedit.sdb /cfg C:\temp\secpol.cfg /areas SECURITYPOLICY
Remove-Item C:\temp\secpol.cfg

# 6. Hardening: Desativar conta Guest
Disable-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
Write-Host "Conta Guest desativada."

# 7. Criar estrutura de pastas em D:\DADOS
$folders = @(
    "D:\DADOS\Publico",
    "D:\DADOS\Confidencial",
    "D:\DADOS\Departamentos\RH",
    "D:\DADOS\Departamentos\Financeiro",
    "D:\DADOS\Departamentos\TI"
)
foreach ($folder in $folders) {
    New-Item -Path $folder -ItemType Directory -Force
    Write-Host "Pasta $folder criada."
}

# 8. Configurar firewall
Write-Host "Configurando firewall..."
# Permitir SMB (porta 445) para compartilhamento de arquivos
New-NetFirewallRule -Name "Allow-SMB-In" -DisplayName "Allow SMB Inbound" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow
# Permitir RDP (porta 3389) temporariamente, apenas de IPs confiáveis
New-NetFirewallRule -Name "Allow-RDP-In" -DisplayName "Allow RDP Inbound" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow -RemoteAddress "192.168.2.0/24"
# Bloquear todo o resto por padrão
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -DefaultOutboundAction Allow

# 9. Ativar logs de eventos para auditoria
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Object Access" /success:enable /failure:enable
Write-Host "Logs de auditoria ativados."

# 10. Mensagem de conclusão
Write-Host "Configuração inicial concluída. Reinicie o servidor para aplicar todas as mudanças."