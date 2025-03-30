# Script: Create-WSUS-GPO.ps1
# Descrição: Cria e configura uma GPO para aplicar atualizações WSUS a todos no domínio
# Requisitos: Executar como administrador no controlador de domínio
# Data: 30 de Março de 2025

#Requires -RunAsAdministrator

# Variáveis
$GpoName = "WSUS Updates"
$DomainName = "aguiar.local"
$WsusServer = "http://srv-dc-01.aguiar.local:8530"

try {
    # Verifica se o script está sendo executado como administrador
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "Este script deve ser executado como administrador no controlador de domínio!"
        exit 1
    }

    # Verifica se o módulo GroupPolicy está disponível
    if (-not (Get-Module -ListAvailable -Name GroupPolicy)) {
        Write-Error "O módulo GroupPolicy não está disponível. Execute este script em um controlador de domínio com as ferramentas de gerenciamento instaladas."
        exit 1
    }

    # Cria a GPO, se não existir
    $gpo = Get-GPO -Name $GpoName -ErrorAction SilentlyContinue
    if (-not $gpo) {
        Write-Host "Criando a GPO '$GpoName'..." -ForegroundColor Green
        $gpo = New-GPO -Name $GpoName -ErrorAction Stop
        Write-Host "GPO criada com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "A GPO '$GpoName' já existe." -ForegroundColor Yellow
    }

    # Configura as políticas de Windows Update
    Write-Host "Configurando políticas de Windows Update na GPO..." -ForegroundColor Green

    # Especificar o servidor WSUS
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" `
        -ValueName "WUServer" -Type String -Value $WsusServer -ErrorAction Stop
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" `
        -ValueName "WUStatusServer" -Type String -Value $WsusServer -ErrorAction Stop

    # Habilitar atualizações automáticas (Download automático e instalação programada às 03:00)
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" `
        -ValueName "NoAutoUpdate" -Type DWord -Value 0 -ErrorAction Stop
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" `
        -ValueName "AUOptions" -Type DWord -Value 4 -ErrorAction Stop
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" `
        -ValueName "ScheduledInstallDay" -Type DWord -Value 0 -ErrorAction Stop  # 0 = Todos os dias
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" `
        -ValueName "ScheduledInstallTime" -Type DWord -Value 3 -ErrorAction Stop  # 03:00

    # Permitir instalação imediata de atualizações críticas
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" `
        -ValueName "AutoInstallMinorUpdates" -Type DWord -Value 1 -ErrorAction Stop

    # Habilitar o cliente para usar o WSUS
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" `
        -ValueName "UseWUServer" -Type DWord -Value 1 -ErrorAction Stop

    Write-Host "Políticas de Windows Update configuradas com sucesso!" -ForegroundColor Green

    # Vincula a GPO ao domínio
    $gpoLink = Get-GPInheritance -Target "dc=aguiar,dc=local" -ErrorAction SilentlyContinue
    if (-not ($gpoLink.GpoLinks | Where-Object { $_.DisplayName -eq $GpoName })) {
        Write-Host "Vinculando a GPO ao domínio $DomainName..." -ForegroundColor Green
        New-GPLink -Name $GpoName -Target "dc=aguiar,dc=local" -LinkEnabled Yes -ErrorAction Stop
        Write-Host "GPO vinculada ao domínio com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "A GPO já está vinculada ao domínio." -ForegroundColor Yellow
    }

    # Força a atualização da política no servidor local
    Write-Host "Aplicando a GPO no servidor local..." -ForegroundColor Green
    gpupdate /force
    Write-Host "Atualização da política concluída!" -ForegroundColor Green

} catch {
    Write-Error "Erro durante a execução: $($_.Exception.Message)"
    exit 1
}

Write-Host "GPO '$GpoName' criada e configurada com sucesso para aplicar atualizações via WSUS!" -ForegroundColor Cyan
Write-Host "Os clientes no domínio $DomainName agora buscarão atualizações em $WsusServer." -ForegroundColor Cyan