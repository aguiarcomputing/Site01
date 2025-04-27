# Verifica se está sendo executado como administrador
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Tentando executar como administrador..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Inicializa código de saída
$ExitCode = 0

# Inicia log
$LogPath = "C:\Logs\ServerConfig_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
if (-not (Test-Path "C:\Logs")) {
    New-Item -Path "C:\Logs" -ItemType Directory | Out-Null
}
Start-Transcript -Path $LogPath -Append

# Solicita senha do administrador de forma segura
Write-Host "Digite a nova senha do administrador:"
$AdminPassword = Read-Host -AsSecureString

# Atualiza a senha do administrador
try {
    Write-Host "Atualizando senha do administrador..."
    $AdminUser = Get-LocalUser | Where-Object { $_.SID -like "*-500" }
    if ($AdminUser) {
        $AdminUser | Set-LocalUser -Password $AdminPassword
        Write-Host "Senha do administrador atualizada com sucesso."
    } else {
        Write-Host "Conta de administrador local não encontrada!" -ForegroundColor Red
        $ExitCode = 1
    }
} catch {
    Write-Host "Erro ao atualizar senha: $_" -ForegroundColor Red
    $ExitCode = 1
}

# Configurações de segurança
try {
    Write-Host "Aplicando configurações de segurança..."
    
    # Desativa SMBv1
    Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart
    
    # Configura firewall
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    Write-Host "Firewall habilitado para todos os perfis."
    
    # Adiciona regra para permitir RDP (porta 3389) nos perfis Domain e Private
    $RdpRuleName = "Allow RDP"
    if (-not (Get-NetFirewallRule -DisplayName $RdpRuleName -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $RdpRuleName -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow -Profile Domain,Private
        Write-Host "Regra de firewall criada para permitir RDP (porta 3389) nos perfis Domain e Private."
    } else {
        Write-Host "Regra de firewall para RDP já existe." -ForegroundColor Yellow
    }
    
    # Desativa acesso remoto ao Registro
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurePipeServers\winreg"
    if (-not (Test-Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $RegPath -Name "RemoteRegAccess" -Value 0
    
    # Desativa conta de convidado
    try {
        Write-Host "Desativando conta de convidado..."
        $GuestUser = Get-LocalUser | Where-Object { $_.SID -like "*-501" }
        if ($GuestUser) {
            Disable-LocalUser -Name $GuestUser.Name -ErrorAction Stop
            Write-Host "Conta de convidado desativada com sucesso."
        } else {
            Write-Host "Conta de convidado não encontrada." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Erro ao desativar conta de convidado: $_" -ForegroundColor Yellow
    }
    
    # Desativa LLMNR
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Value 0 -ErrorAction SilentlyContinue
    if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Value 0
    }
    
    # Desativa NetBIOS sobre TCP/IP
    $NetBiosRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces"
    Get-ChildItem $NetBiosRegPath | ForEach-Object {
        Set-ItemProperty -Path "$NetBiosRegPath\$($_.PSChildName)" -Name "NetbiosOptions" -Value 2
    }
    
    Write-Host "Configurações de segurança aplicadas."
} catch {
    Write-Host "Erro ao aplicar configurações de segurança: $_" -ForegroundColor Red
    $ExitCode = 1
}

# Configura políticas de senha rigorosas via secedit
try {
    Write-Host "Configurando políticas de senha rigorosas..."
    $SecPolFile = "C:\Temp\secpol.inf"
    if (-not (Test-Path "C:\Temp")) {
        New-Item -Path "C:\Temp" -ItemType Directory | Out-Null
    }
    
    $SecPolContent = @"
[Unicode]
Unicode=yes
[Version]
signature="$CHICAGO$"
Revision=1
[PasswordComplexity]
PasswordComplexity=1
[MaximumPasswordAge]
MaximumPasswordAge=90
[MinimumPasswordLength]
MinimumPasswordLength=12
[PasswordHistorySize]
PasswordHistorySize=24
[LockoutBadCount]
LockoutBadCount=5
[LockoutDuration]
LockoutDuration=30
[ResetLockoutCount]
ResetLockoutCount=30
"@
    
    $SecPolContent | Out-File -FilePath $SecPolFile -Encoding Unicode
    secedit /configure /db secedit.sdb /cfg $SecPolFile /areas SECURITYPOLICY
    Remove-Item -Path $SecPolFile -Force
    Write-Host "Políticas de senha configuradas: comprimento mínimo 12, expiração 90 dias, histórico 24, bloqueio após 5 tentativas."
} catch {
    Write-Host "Erro ao configurar políticas de senha: $_" -ForegroundColor Red
    $ExitCode = 1
}

# Instala atualizações do Windows
try {
    Write-Host "Instalando atualizações do Windows..."
    if (Test-Connection -ComputerName "www.powershellgallery.com" -Count 1 -Quiet) {
        Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -ErrorAction Stop
        Import-Module PSWindowsUpdate
        Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot
        Write-Host "Atualizações instaladas. Reinicie o servidor manualmente." -ForegroundColor Yellow
    } else {
        Write-Host "Não foi possível conectar ao PowerShell Gallery. Pulando atualizações." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Erro ao instalar atualizações: $_" -ForegroundColor Red
    $ExitCode = 1
}

# Resumo final
Write-Host "Configuração concluída com código de saída: $ExitCode" -ForegroundColor Green
Write-Host "Ações realizadas:"
Write-Host "- Senha do administrador atualizada"
Write-Host "- Configurações de segurança aplicadas (SMBv1, firewall, Registro, LLMNR, NetBIOS)"
Write-Host "- Conta de convidado desativada"
Write-Host "- Políticas de senha configuradas"
Write-Host "- Atualizações do Windows instaladas (se aplicável)"
Write-Host "Reinicie o servidor manualmente para aplicar todas as alterações." -ForegroundColor Yellow
Write-Host "Log salvo em: $LogPath"

# Finaliza log e retorna código de saída
Stop-Transcript
Exit $ExitCode