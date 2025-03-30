# Script: Validate-WSUS-Firewall.ps1
# Descrição: Valida e configura o firewall para permitir acesso ao WSUS
# Requisitos: Executar como administrador
# Data: 30 de Março de 2025

#Requires -RunAsAdministrator

# Variáveis
$WsusPort = 8530              # Porta padrão do WSUS
$ServerIP = "192.168.2.107"   # IP do servidor WSUS
$RuleName = "WSUS Inbound TCP 8530"  # Nome da regra do firewall

try {
    # Verifica se o script está sendo executado como administrador
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "Este script deve ser executado como administrador!"
        exit 1
    }

    # Verifica se o firewall está habilitado
    $firewallProfile = Get-NetFirewallProfile -Name Domain -ErrorAction Stop
    if (-not $firewallProfile.Enabled) {
        Write-Warning "O perfil de firewall do domínio está desativado. Habilitando-o..."
        Set-NetFirewallProfile -Name Domain -Enabled True -ErrorAction Stop
        Write-Host "Perfil de firewall do domínio habilitado." -ForegroundColor Green
    } else {
        Write-Host "O perfil de firewall do domínio já está habilitado." -ForegroundColor Yellow
    }

    # Verifica se já existe uma regra para o WSUS
    Write-Host "Verificando regras de firewall existentes para o WSUS..." -ForegroundColor Green
    $existingRule = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue

    if ($existingRule) {
        # Verifica se a regra está habilitada e configurada corretamente
        $rulePort = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $existingRule -ErrorAction Stop
        if ($existingRule.Enabled -and $rulePort.Protocol -eq "TCP" -and $rulePort.LocalPort -eq $WsusPort) {
            Write-Host "A regra '$RuleName' já existe e está configurada corretamente para TCP/$WsusPort." -ForegroundColor Yellow
        } else {
            Write-Warning "A regra '$RuleName' existe, mas está mal configurada ou desativada. Reconfigurando..."
            Remove-NetFirewallRule -DisplayName $RuleName -ErrorAction Stop
            New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Protocol TCP -LocalPort $WsusPort -Action Allow -Enabled True -Profile Domain -ErrorAction Stop
            Write-Host "Regra '$RuleName' reconfigurada com sucesso!" -ForegroundColor Green
        }
    } else {
        # Cria uma nova regra de firewall para o WSUS
        Write-Host "Criando regra de firewall para permitir acesso ao WSUS na porta $WsusPort..." -ForegroundColor Green
        New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Protocol TCP -LocalPort $WsusPort -Action Allow -Enabled True -Profile Domain -ErrorAction Stop
        Write-Host "Regra '$RuleName' criada com sucesso!" -ForegroundColor Green
    }

    # Testa a conectividade na porta WSUS a partir do servidor local
    Write-Host "Testando a conectividade na porta $WsusPort..." -ForegroundColor Green
    $testConnection = Test-NetConnection -ComputerName $ServerIP -Port $WsusPort -ErrorAction Stop
    if ($testConnection.TcpTestSucceeded) {
        Write-Host "A porta $WsusPort está aberta e acessível localmente em $ServerIP!" -ForegroundColor Green
    } else {
        Write-Warning "Falha ao conectar à porta $WsusPort em $ServerIP. Verifique o serviço WSUS ou outras regras de firewall."
    }

    # Informa como testar a partir de um cliente
    Write-Host "Para testar de um cliente, execute no cliente: Test-NetConnection -ComputerName $ServerIP -Port $WsusPort" -ForegroundColor Cyan

} catch {
    Write-Error "Erro durante a execução: $($_.Exception.Message)"
    exit 1
}

Write-Host "Validação e configuração do firewall para WSUS concluídas com sucesso!" -ForegroundColor Cyan