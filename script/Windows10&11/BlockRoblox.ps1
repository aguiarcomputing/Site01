# Script para bloquear conexões do Roblox no Firewall do Windows
# Deve ser executado como administrador

# Função para verificar se está rodando como administrador
function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Verifica privilégios administrativos
if (-not (Test-Admin)) {
    Write-Host "Este script precisa ser executado como administrador. Inicie o PowerShell como administrador e tente novamente."
    exit
}

# Caminho típico do executável do Roblox (ajuste se necessário)
$robloxPath = "$env:LOCALAPPDATA\Roblox\Versions\RobloxPlayerBeta.exe"

# Verifica se o executável existe
if (-not (Test-Path $robloxPath)) {
    Write-Host "Executável do Roblox não encontrado em $robloxPath. Verifique o caminho e tente novamente."
    exit
}

# Nome das regras do firewall
$ruleNameInbound = "Block_Roblox_Inbound"
$ruleNameOutbound = "Block_Roblox_Outbound"

# Remove regras existentes com o mesmo nome, se houver
Remove-NetFirewallRule -Name $ruleNameInbound -ErrorAction SilentlyContinue
Remove-NetFirewallRule -Name $ruleNameOutbound -ErrorAction SilentlyContinue

# Cria regra para bloquear conexões de entrada
New-NetFirewallRule -Name $ruleNameInbound `
    -DisplayName "Bloquear Roblox (Entrada)" `
    -Direction Inbound `
    -Program $robloxPath `
    -Action Block `
    -Profile Any `
    -Description "Bloqueia todas as conexões de entrada do Roblox"

# Cria regra para bloquear conexões de saída
New-NetFirewallRule -Name $ruleNameOutbound `
    -DisplayName "Bloquear Roblox (Saída)" `
    -Direction Outbound `
    -Program $robloxPath `
    -Action Block `
    -Profile Any `
    -Description "Bloqueia todas as conexões de saída do Roblox"

# Encerra processos ativos do Roblox
Get-Process -Name "RobloxPlayerBeta" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Conexões do Roblox foram bloqueadas no Firewall do Windows e processos ativos foram encerrados."
Write-Host "Para verificar, tente abrir o Roblox e confirme se ele não se conecta."
Write-Host "Para desfazer, remova as regras '$ruleNameInbound' e '$ruleNameOutbound' no Firewall do Windows."