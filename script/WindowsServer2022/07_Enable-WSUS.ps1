# Script: Enable-WSUS.ps1
# Descrição: Instala e configura o WSUS para buscar atualizações seguras do Windows
# Requisitos: Executar como administrador
# Data: 30 de Março de 2025

#Requires -RunAsAdministrator

# Variáveis
$WSUSContentPath = "C:\WSUS"  # Diretório para armazenar atualizações
$WSUSPort = 8530              # Porta padrão do WSUS

try {
    # Verifica se o script está sendo executado como administrador
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "Este script deve ser executado como administrador!"
        exit 1
    }

    # Instala o WSUS
    Write-Host "Instalando o Windows Server Update Services..." -ForegroundColor Green
    $feature = Get-WindowsFeature -Name "UpdateServices"
    if (-not $feature.Installed) {
        Install-WindowsFeature -Name "UpdateServices", "UpdateServices-WidDB", "UpdateServices-Services" -IncludeManagementTools -ErrorAction Stop
        Write-Host "WSUS instalado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "WSUS já está instalado." -ForegroundColor Yellow
    }

    # Cria o diretório para conteúdo, se não existir
    if (-not (Test-Path $WSUSContentPath)) {
        Write-Host "Criando diretório $WSUSContentPath para armazenar atualizações..." -ForegroundColor Green
        New-Item -Path $WSUSContentPath -ItemType Directory -ErrorAction Stop
    }

    # Configura o WSUS após a instalação
    Write-Host "Executando configuração pós-instalação do WSUS..." -ForegroundColor Green
    $wsusUtil = "C:\Program Files\Update Services\Tools\WsusUtil.exe"
    if (Test-Path $wsusUtil) {
        & $wsusUtil postinstall CONTENT_DIR=$WSUSContentPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Configuração pós-instalação concluída!" -ForegroundColor Green
        } else {
            Write-Error "Erro na configuração pós-instalação do WSUS. Verifique os logs em %ProgramFiles%\Update Services\LogFiles."
            exit 1
        }
    } else {
        Write-Error "WsusUtil.exe não encontrado. A instalação pode ter falhado."
        exit 1
    }

    # Configura o WSUS para buscar atualizações seguras
    Write-Host "Configurando o WSUS para buscar atualizações seguras..." -ForegroundColor Green
    $wsus = Get-WsusServer -Name "localhost" -PortNumber $WSUSPort -ErrorAction Stop

    # Configurações gerais
    $wsusConfig = $wsus.GetConfiguration()
    $wsusConfig.AllUpdateLanguagesEnabled = $false
    $wsusConfig.SetEnabledUpdateLanguages("en")  # Apenas inglês
    $wsusConfig.MuRollup = $true                # Inclui atualizações do Microsoft Update
    $wsusConfig.Save()

    # Define produtos (Windows) e classificações (atualizações de segurança)
    $subscription = $wsus.GetSubscription()
    $subscription.GetUpdateCategories() | Where-Object { $_.Title -match "Windows" } | ForEach-Object { $subscription.SetSynchronizationCategories($_) }
    $subscription.GetUpdateClassifications() | Where-Object { $_.Title -eq "Security Updates" } | ForEach-Object { $subscription.SetSynchronizationClassifications($_) }
    $subscription.Save()

    # Inicia a sincronização com o Microsoft Update
    Write-Host "Iniciando sincronização com o Microsoft Update..." -ForegroundColor Green
    $subscription.StartSynchronization()
    while ($subscription.GetSynchronizationStatus() -eq "Running") {
        Write-Host "Sincronização em andamento..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
    Write-Host "Sincronização concluída!" -ForegroundColor Green

    # Configura aprovação automática para atualizações de segurança
    Write-Host "Configurando aprovação automática para atualizações de segurança..." -ForegroundColor Green
    $approvalRule = $wsus.CreateInstallApprovalRule("Aprovar Atualizações de Segurança")
    $classification = $wsus.GetUpdateClassifications() | Where-Object { $_.Title -eq "Security Updates" }
    $approvalRule.GetUpdateClassifications().Add($classification)
    $approvalRule.Enabled = $true
    $approvalRule.Save()
    $approvalRule.ApplyRule()
    Write-Host "Regra de aprovação automática configurada!" -ForegroundColor Green

    # Verifica o status do serviço
    $wsusService = Get-Service -Name "WsusService" -ErrorAction Stop
    if ($wsusService.Status -ne "Running") {
        Start-Service -Name "WsusService" -ErrorAction Stop
        Write-Host "Serviço WSUS iniciado!" -ForegroundColor Green
    } else {
        Write-Host "Serviço WSUS já está em execução." -ForegroundColor Yellow
    }

} catch {
    Write-Error "Erro durante a execução: $($_.Exception.Message)"
    exit 1
}

Write-Host "WSUS configurado com sucesso para buscar e aprovar atualizações seguras do Windows!" -ForegroundColor Cyan