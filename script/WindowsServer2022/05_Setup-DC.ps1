# Parâmetros do domínio
$DomainName = "empresa.local"
$NetBIOSName = "EMPRESA"
$SafeModeAdminPassword = ConvertTo-SecureString "bz07fx$#oela14" -AsPlainText -Force
$ForestMode = "WinThreshold"
$DomainMode = "WinThreshold"
$LogPath = "C:\Logs\ADDS_Install.log"

# Criar diretório de logs
New-Item -Path "C:\Logs" -ItemType Directory -Force

# Iniciar logging
Start-Transcript -Path $LogPath

try {
    # Verificar endereço IP estático
    $ipConfig = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "Loopback" }
    if (-not $ipConfig.IPAddress) {
        throw "Endereço IP estático não configurado."
    }
    Write-Host "Endereço IP configurado: $($ipConfig.IPAddress)"

    # Instalar função AD DS e ferramentas
    Write-Host "Instalando AD DS..."
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -IncludeAllSubFeature -ErrorAction Stop

    # Instalar função DNS
    Write-Host "Instalando DNS..."
    Install-WindowsFeature -Name DNS -IncludeManagementTools -ErrorAction Stop

    # Promover a controlador de domínio
    Write-Host "Promovendo a controlador de domínio..."
    Install-ADDSForest `
        -DomainName $DomainName `
        -DomainNetBIOSName $NetBIOSName `
        -ForestMode $ForestMode `
        -DomainMode $DomainMode `
        -SafeModeAdministratorPassword $SafeModeAdminPassword `
        -InstallDNS:$true `
        -NoRebootOnCompletion:$false `
        -Force:$true `
        -ErrorAction Stop

    Write-Host "Configuração concluída com sucesso. O servidor será reiniciado."
}
catch {
    Write-Host "Erro durante a execução: $_" -ForegroundColor Red
    exit 1
}
finally {
    Stop-Transcript
}