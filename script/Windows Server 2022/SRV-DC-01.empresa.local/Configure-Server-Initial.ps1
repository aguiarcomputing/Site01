# Script para configuração inicial do servidor de arquivos SRV-DC-01.empresa.local
# Requisitos: Windows Server 2022, executado como administrador

# Verificar se o script está sendo executado como administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Este script deve ser executado como administrador."
    exit 1
}

# Criar diretório temporário para logs
$logPath = "C:\Temp\ServerConfig.log"
if (-not (Test-Path "C:\Temp")) { New-Item -Path "C:\Temp" -ItemType Directory -Force }
function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Write-Host $logMessage
    Add-Content -Path $logPath -Value $logMessage
}

# 1. Atualizar o sistema
Write-Log "Instalando atualizações do Windows..."
try {
    Install-WindowsUpdate -AcceptAll -Install -IgnoreReboot -ErrorAction Stop
    Write-Log "Atualizações instaladas. Reinicialização pendente para aplicação completa."
} catch {
    Write-Log "Erro ao instalar atualizações: $_"
}

# 2. Configurar hostname
$hostname = "SRV-DC-01.empresa.local"
if ($env:COMPUTERNAME -ne $hostname) {
    try {
        Rename-Computer -NewName $hostname -Force -ErrorAction Stop
        Write-Log "Hostname alterado para $hostname. Reinicialização necessária para aplicar."
    } catch {
        Write-Log "Erro ao alterar hostname: $_"
    }
} else {
    Write-Log "Hostname já configurado como $hostname."
}

# 3. Configurar IP estático
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
if ($interface) {
    try {
        New-NetIPAddress -InterfaceAlias $interface.Name -IPAddress "192.168.2.200" -PrefixLength 24 -DefaultGateway "192.168.2.1" -Force -ErrorAction Stop
        Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses ("192.168.2.200", "8.8.8.8") -ErrorAction Stop
        Write-Log "IP estático configurado em $($interface.Name)."
    } catch {
        Write-Log "Erro ao configurar IP estático: $_"
    }
} else {
    Write-Log "Nenhuma interface de rede ativa encontrada."
}

# 4. Hardening: Desativar serviços desnecessários
$servicesToDisable = @("Telnet", "SNMP", "FTP", "Xbox*")
foreach ($service in $servicesToDisable) {
    try {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction Stop
            Write-Log "Serviço $($svc.Name) desativado."
        } else {
            Write-Log "Serviço $service não encontrado."
        }
    } catch {
        Write-Log "Erro ao desativar serviço $service: $_"
    }
}

# 5. Hardening: Configurar políticas de senha
Write-Log "Configurando políticas de senha..."
try {
    net accounts /minpwlen:12 /maxpwage:90 /complexity:enable
    Write-Log "Políticas de senha configuradas: comprimento mínimo 12, expiração em 90 dias, complexidade ativada."
} catch {
    Write-Log "Erro ao configurar políticas de senha: $_"
}

# 6. Hardening: Desativar conta Guest
try {
    Disable-LocalUser -Name "Guest" -ErrorAction Stop
    Write-Log "Conta Guest desativada."
} catch {
    Write-Log "Erro ao desativar conta Guest: $_"
}

# 7. Criar estrutura de pastas em D:\ARQUIVOS
$folders = @(
    "D:\ARQUIVOS\Publico",
    "D:\ARQUIVOS\Confidencial",
    "D:\ARQUIVOS\Departamentos\RH",
    "D:\ARQUIVOS\Departamentos\Financeiro",
    "D:\ARQUIVOS\Departamentos\TI"
)
foreach ($folder in $folders) {
    try {
        New-Item -Path $folder -ItemType Directory -Force -ErrorAction Stop
        Write-Log "Pasta $folder criada."
    } catch {
        Write-Log "Erro ao criar pasta $folder: $_"
    }
}

# 8. Configurar firewall
Write-Log "Configurando firewall..."
try {
    New-NetFirewallRule -Name "Allow-SMB-In" -DisplayName "Allow SMB Inbound" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow -ErrorAction Stop
    New-NetFirewallRule -Name "Allow-RDP-In" -DisplayName "Allow RDP Inbound" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow -RemoteAddress "192.168.2.0/24" -ErrorAction Stop
    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -DefaultOutboundAction Allow -ErrorAction Stop
    Write-Log "Regras de firewall configuradas."
} catch {
    Write-Log "Erro ao configurar firewall: $_"
}

# 9. Ativar logs de eventos para auditoria
Write-Log "Configurando logs de auditoria..."
try {
    auditpol /set /category:"Account Logon" /success:enable /failure:enable
    auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
    auditpol /set /category:"Object Access" /success:enable /failure:enable
    Write-Log "Logs de auditoria ativados."
} catch {
    Write-Log "Erro ao configurar logs de auditoria: $_"
}

# 10. Mensagem de conclusão
Write-Log "Configuração inicial concluída. Algumas alterações (como hostname e atualizações) requerem reinicialização manual para serem aplicadas completamente. Log salvo em $logPath."