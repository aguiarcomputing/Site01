# Script 2: Configuração do WSUS - Windows Server 2022

# Verifica privilégios
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Execute este script como administrador!"
    Exit
}

# Instala o WSUS
Write-Host "Instalando o Windows Server Update Services..."
Install-WindowsFeature -Name UpdateServices -IncludeManagementTools

# Define o diretório para armazenar atualizações
$WSUSContentPath = "C:\WSUS"
if (-not (Test-Path $WSUSContentPath)) {
    New-Item -Path $WSUSContentPath -ItemType Directory
}

# Configura o WSUS
Write-Host "Configurando o WSUS..."
& "C:\Program Files\Update Services\Tools\WsusUtil.exe" postinstall CONTENT_DIR=$WSUSContentPath

# Configura opções iniciais via PowerShell (exemplo básico)
$WSUSServer = Get-WsusServer
$WSUSServerConfig = $WSUSServer.GetConfiguration()
$WSUSServerConfig.AllUpdateLanguagesEnabled = $false
$WSUSServerConfig.SetEnabledUpdateLanguages("en")  # Apenas inglês
$WSUSServerConfig.Save()

# Sincroniza com o Microsoft Update
Write-Host "Sincronizando com o Microsoft Update..."
$Subscription = $WSUSServer.GetSubscription()
$Subscription.StartSynchronization()
while ($Subscription.GetSynchronizationStatus() -eq "Running") {
    Write-Host "Sincronização em andamento..."
    Start-Sleep -Seconds 10
}

Write-Host "WSUS configurado com sucesso!"