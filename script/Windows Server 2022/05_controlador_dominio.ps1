# Script 4: Configuração como Controlador de Domínio - Windows Server 2022

# Verifica privilégios
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Execute este script como administrador!"
    Exit
}

# Instala o AD Domain Services
Write-Host "Instalando AD Domain Services..."
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promove o servidor a controlador de domínio
Write-Host "Promovendo a controlador de domínio..."
$SafeModePassword = ConvertTo-SecureString "bz07fx$#oela14" -AsPlainText -Force
Install-ADDSForest `
    -DomainName "aguiar.local" `
    -DomainNetbiosName "AGUIAR" `
    -ForestMode "WinThreshold" `
    -DomainMode "WinThreshold" `
    -InstallDns:$true `
    -SafeModeAdministratorPassword $SafeModePassword `
    -Force

Write-Host "Controlador de domínio configurado. O servidor será reiniciado."