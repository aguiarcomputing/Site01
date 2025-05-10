#Requires -RunAsAdministrator

# Script para instalar e configurar o UniFi Network

# Função para verificar e baixar a versão mais recente do UniFi Network
function Get-LatestUniFiInstaller {
    $downloadPage = Invoke-WebRequest -Uri "https://www.ui.com/download/unifi/" -UseBasicParsing
    $installerUrl = ($downloadPage.Links | Where-Object { $_.href -like "*UniFi-installer.exe" }).href | Select-Object -First 1
    
    if (-not $installerUrl) {
        Write-Error "Não foi possível encontrar o link de download do UniFi-installer.exe"
        exit 1
    }
    
    $outputPath = "$env:TEMP\UniFi-installer.exe"
    Write-Host "Baixando UniFi Network installer de $installerUrl..."
    Invoke-WebRequest -Uri $installerUrl -OutFile $outputPath
    return $outputPath
}

# Função para configurar regras de firewall
function Set-FirewallRules {
    $ports = @(
        @{Name="UniFi-TCP-8080"; Protocol="TCP"; Port=8080},
        @{Name="UniFi-TCP-8843"; Protocol="TCP"; Port=8843},
        @{Name="UniFi-UDP-10001"; Protocol="UDP"; Port=10001},
        @{Name="UniFi-UDP-3478"; Protocol="UDP"; Port=3478}
    )

    foreach ($port in $ports) {
        Write-Host "Configurando regra de firewall para $($port.Protocol) porta $($port.Port)..."
        New-NetFirewallRule -DisplayName $port.Name `
                           -Direction Inbound `
                           -Protocol $port.Protocol `
                           -LocalPort $port.Port `
                           -Action Allow `
                           -Enabled True `
                           -ErrorAction SilentlyContinue
    }
}

# Função para verificar se o MongoDB está instalado (versão mínima 3.6)
function Test-MongoDB {
    Write-Host "Verificando instalação do MongoDB..."
    # MongoDB é empacotado com o UniFi, mas podemos verificar a versão
    $mongoPath = Join-Path $env:ProgramFiles "UniFi Network\mongodb\bin\mongo.exe"
    if (Test-Path $mongoPath) {
        $version = & $mongoPath --version
        if ($version -match "3\.[6-9]|\d+\.\d+") {
            Write-Host "MongoDB versão compatível encontrada."
            return $true
        }
    }
    return $false
}

# Função principal
function Install-UniFiNetwork {
    try {
        # Baixar instalador
        $installerPath = Get-LatestUniFiInstaller

        # Instalar UniFi Network
        Write-Host "Iniciando instalação do UniFi Network..."
        Start-Process -FilePath $installerPath -ArgumentList "/quiet" -Wait

        # Configurar firewall
        Set-FirewallRules

        # Verificar MongoDB
        if (-not (Test-MongoDB)) {
            Write-Warning "MongoDB não encontrado ou versão incompatível. O instalador deve ter incluído automaticamente."
        }

        # Iniciar aplicativo UniFi Network
        $uniFiPath = Join-Path $env:ProgramFiles "UniFi Network\UniFi.exe"
        if (Test-Path $uniFiPath) {
            Write-Host "Iniciando UniFi Network..."
            Start-Process -FilePath $uniFiPath
        } else {
            Write-Error "Aplicativo UniFi Network não encontrado em $uniFiPath"
            exit 1
        }

        # Abrir navegador para configuração
        Write-Host "Abrindo navegador para https://localhost:8443..."
        Start-Process "https://localhost:8443"

        Write-Host "Instalação e configuração concluídas. Siga o assistente de configuração no navegador."
    }
    catch {
        Write-Error "Erro durante a instalação: $_"
        exit 1
    }
    finally {
        # Limpar instalador
        if (Test-Path $installerPath) {
            Remove-Item $installerPath -Force
        }
    }
}

# Executar instalação
Install-UniFiNetwork