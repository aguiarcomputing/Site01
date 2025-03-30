# Script: Create-Custom-OUs-and-GPOs.ps1
# Descrição: Cria OUs personalizadas e aplica GPOs específicas
# Requisitos: Executar como administrador no controlador de domínio
# Data: 30 de Março de 2025

#Requires -RunAsAdministrator
#Requires -Modules ActiveDirectory, GroupPolicy

# Variáveis
$DomainName = "aguiar.local"
$DomainDN = "DC=aguiar,DC=local"
$WsusServer = "http://srv-dc-01.aguiar.local:8530"

try {
    # Verifica se o script está sendo executado como administrador
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "Este script deve ser executado como administrador no controlador de domínio!"
        exit 1
    }

    # Verifica se os módulos necessários estão disponíveis
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory) -or -not (Get-Module -ListAvailable -Name GroupPolicy)) {
        Write-Error "Os módulos ActiveDirectory e/ou GroupPolicy não estão disponíveis. Instale as ferramentas RSAT."
        exit 1
    }

    # Criação das OUs
    Write-Host "Criando Organizational Units..." -ForegroundColor Green

    # OU: Grupos de Usuários
    $ouUsers = Get-ADOrganizationalUnit -Filter "Name -eq 'Grupos de Usuários'" -SearchBase $DomainDN -ErrorAction SilentlyContinue
    if (-not $ouUsers) {
        New-ADOrganizationalUnit -Name "Grupos de Usuários" -Path $DomainDN -Description "OU para usuários do domínio" -ErrorAction Stop
        Write-Host "OU 'Grupos de Usuários' criada com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "OU 'Grupos de Usuários' já existe." -ForegroundColor Yellow
    }

    # OU: Grupos de Suporte TI
    $ouSupportTI = Get-ADOrganizationalUnit -Filter "Name -eq 'Grupos de Suporte TI'" -SearchBase $DomainDN -ErrorAction SilentlyContinue
    if (-not $ouSupportTI) {
        New-ADOrganizationalUnit -Name "Grupos de Suporte TI" -Path $DomainDN -Description "OU para equipe de suporte TI" -ErrorAction Stop
        Write-Host "OU 'Grupos de Suporte TI' criada com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "OU 'Grupos de Suporte TI' já existe." -ForegroundColor Yellow
    }

    # OU: Grupos de Computadores
    $ouComputers = Get-ADOrganizationalUnit -Filter "Name -eq 'Grupos de Computadores'" -SearchBase $DomainDN -ErrorAction SilentlyContinue
    if (-not $ouComputers) {
        New-ADOrganizationalUnit -Name "Grupos de Computadores" -Path $DomainDN -Description "OU para estações de trabalho" -ErrorAction Stop
        Write-Host "OU 'Grupos de Computadores' criada com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "OU 'Grupos de Computadores' já existe." -ForegroundColor Yellow
    }

    # OU: Grupos de Servidores Linux
    $ouLinuxServers = Get-ADOrganizationalUnit -Filter "Name -eq 'Grupos de Servidores Linux'" -SearchBase $DomainDN -ErrorAction SilentlyContinue
    if (-not $ouLinuxServers) {
        New-ADOrganizationalUnit -Name "Grupos de Servidores Linux" -Path $DomainDN -Description "OU para servidores Linux" -ErrorAction Stop
        Write-Host "OU 'Grupos de Servidores Linux' criada com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "OU 'Grupos de Servidores Linux' já existe." -ForegroundColor Yellow
    }

    # OU: Grupos de Servidores Windows Server
    $ouWindowsServers = Get-ADOrganizationalUnit -Filter "Name -eq 'Grupos de Servidores Windows Server'" -SearchBase $DomainDN -ErrorAction SilentlyContinue
    if (-not $ouWindowsServers) {
        New-ADOrganizationalUnit -Name "Grupos de Servidores Windows Server" -Path $DomainDN -Description "OU para servidores Windows" -ErrorAction Stop
        Write-Host "OU 'Grupos de Servidores Windows Server' criada com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "OU 'Grupos de Servidores Windows Server' já existe." -ForegroundColor Yellow
    }

    # Criação e configuração das GPOs
    Write-Host "Criando e configurando GPOs..." -ForegroundColor Green

    # GPO para Grupos de Usuários: Restrições básicas
    $gpoUsers = Get-GPO -Name "User Restrictions" -ErrorAction SilentlyContinue
    if (-not $gpoUsers) {
        $gpoUsers = New-GPO -Name "User Restrictions" -ErrorAction Stop
        Set-GPRegistryValue -Name "User Restrictions" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
            -ValueName "NoControlPanel" -Type DWord -Value 1 -ErrorAction Stop  # Oculta Painel de Controle
        New-GPLink -Name "User Restrictions" -Target "OU=Grupos de Usuários,$DomainDN" -LinkEnabled Yes -ErrorAction Stop
        Write-Host "GPO 'User Restrictions' criada e vinculada à OU 'Grupos de Usuários'!" -ForegroundColor Green
    } else {
        Write-Host "GPO 'User Restrictions' já existe." -ForegroundColor Yellow
    }

    # GPO para Grupos de Suporte TI: Menos restrições
    $gpoSupportTI = Get-GPO -Name "Support TI Permissions" -ErrorAction SilentlyContinue
    if (-not $gpoSupportTI) {
        $gpoSupportTI = New-GPO -Name "Support TI Permissions" -ErrorAction Stop
        Set-GPRegistryValue -Name "Support TI Permissions" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
            -ValueName "NoControlPanel" -Type DWord -Value 0 -ErrorAction Stop  # Permite Painel de Controle
        New-GPLink -Name "Support TI Permissions" -Target "OU=Grupos de Suporte TI,$DomainDN" -LinkEnabled Yes -ErrorAction Stop
        Write-Host "GPO 'Support TI Permissions' criada e vinculada à OU 'Grupos de Suporte TI'!" -ForegroundColor Green
    } else {
        Write-Host "GPO 'Support TI Permissions' já existe." -ForegroundColor Yellow
    }

    # GPO para Grupos de Computadores: WSUS
    $gpoComputers = Get-GPO -Name "Computer WSUS Updates" -ErrorAction SilentlyContinue
    if (-not $gpoComputers) {
        $gpoComputers = New-GPO -Name "Computer WSUS Updates" -ErrorAction Stop
        Set-GPRegistryValue -Name "Computer WSUS Updates" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" `
            -ValueName "WUServer" -Type String -Value $WsusServer -ErrorAction Stop
        Set-GPRegistryValue -Name "Computer WSUS Updates" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" `
            -ValueName "AUOptions" -Type DWord -Value 4 -ErrorAction Stop  # Download e instalação às 03:00
        Set-GPRegistryValue -Name "Computer WSUS Updates" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" `
            -ValueName "ScheduledInstallTime" -Type DWord -Value 3 -ErrorAction Stop
        New-GPLink -Name "Computer WSUS Updates" -Target "OU=Grupos de Computadores,$DomainDN" -LinkEnabled Yes -ErrorAction Stop
        Write-Host "GPO 'Computer WSUS Updates' criada e vinculada à OU 'Grupos de Computadores'!" -ForegroundColor Green
    } else {
        Write-Host "GPO 'Computer WSUS Updates' já existe." -ForegroundColor Yellow
    }

    # GPO para Grupos de Servidores Linux: Configuração mínima (ex.: firewall)
    $gpoLinuxServers = Get-GPO -Name "Linux Server Config" -ErrorAction SilentlyContinue
    if (-not $gpoLinuxServers) {
        $gpoLinuxServers = New-GPO -Name "Linux Server Config" -ErrorAction Stop
        # Nota: Servidores Linux não aplicam GPOs diretamente, mas a OU pode ser usada para organização
        Write-Host "GPO 'Linux Server Config' criada (sem configurações específicas para Linux)." -ForegroundColor Yellow
        New-GPLink -Name "Linux Server Config" -Target "OU=Grupos de Servidores Linux,$DomainDN" -LinkEnabled Yes -ErrorAction Stop
        Write-Host "GPO 'Linux Server Config' vinculada à OU 'Grupos de Servidores Linux'!" -ForegroundColor Green
    } else {
        Write-Host "GPO 'Linux Server Config' já existe." -ForegroundColor Yellow
    }

    # GPO para Grupos de Servidores Windows Server: Segurança e WSUS
    $gpoWindowsServers = Get-GPO -Name "Windows Server Security" -ErrorAction SilentlyContinue
    if (-not $gpoWindowsServers) {
        $gpoWindowsServers = New-GPO -Name "Windows Server Security" -ErrorAction Stop
        Set-GPRegistryValue -Name "Windows Server Security" -Key "HKLM\Software\Policies\Microsoft\WindowsFirewall\DomainProfile" `
            -ValueName "EnableFirewall" -Type DWord -Value 1 -ErrorAction Stop  # Habilita firewall
        Set-GPRegistryValue -Name "Windows Server Security" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" `
            -ValueName "WUServer" -Type String -Value $WsusServer -ErrorAction Stop  # WSUS
        New-GPLink -Name "Windows Server Security" -Target "OU=Grupos de Servidores Windows Server,$DomainDN" -LinkEnabled Yes -ErrorAction Stop
        Write-Host "GPO 'Windows Server Security' criada e vinculada à OU 'Grupos de Servidores Windows Server'!" -ForegroundColor Green
    } else {
        Write-Host "GPO 'Windows Server Security' já existe." -ForegroundColor Yellow
    }

    # Forçar atualização da política no servidor local
    Write-Host "Aplicando GPOs localmente..." -ForegroundColor Green
    gpupdate /force
    Write-Host "Atualização da política concluída!" -ForegroundColor Green

} catch {
    Write-Error "Erro durante a execução: $($_.Exception.Message)"
    exit 1
}

Write-Host "OUs e GPOs criadas e configuradas com sucesso no domínio $DomainName!" -ForegroundColor Cyan