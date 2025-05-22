# Script para configurar uma conexão VPN L2TP no Windows com verificação de política de execução
# Nome da conexão: VPN_L2TP_ITCONNECT
# Endereço do servidor: 138.122.64.150
# Tipo de VPN: L2TP/IPsec com chave pré-compartilhada
# Chave pré-compartilhada: itconnect
# Credenciais: leandro.pc / r6C4hIukpwrsRAE

# Verifica se o script está sendo executado como administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Este script precisa ser executado como administrador. Iniciando com privilégios elevados..."
    Start-Process powershell -Verb runAs -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`""
    Exit
}

# Verifica e ajusta a política de execução do PowerShell
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "Undefined") {
    Write-Host "A política de execução atual ($currentPolicy) não permite scripts. Alterando para RemoteSigned..."
    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Write-Host "Política de execução alterada para RemoteSigned."
    } catch {
        Write-Host "Erro ao alterar a política de execução: $_"
        Write-Host "Execute manualmente: Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned"
        Exit
    }
} else {
    Write-Host "Política de execução atual ($currentPolicy) é suficiente para executar scripts."
}

# Configurações da VPN
$connectionName = "VPN_L2TP_ITCONNECT"
$serverAddress = "138.122.64.150"
$preSharedKey = "itconnect"
$username = "leandro.pc"
$password = "r6C4hIukpwrsRAE"

# Verifica se a conexão VPN já existe
if (Get-VpnConnection -Name $connectionName -ErrorAction SilentlyContinue) {
    Write-Host "A conexão VPN '$connectionName' já existe. Removendo a conexão existente..."
    Remove-VpnConnection -Name $connectionName -Force
}

# Cria a conexão VPN
try {
    Add-VpnConnection -Name $connectionName `
        -ServerAddress $serverAddress `
        -TunnelType L2tp `
        -EncryptionLevel Required `
        -L2tpPsk $preSharedKey `
        -AuthenticationMethod MSChapv2 `
        -Force
    Write-Host "Conexão VPN '$connectionName' criada com sucesso."
} catch {
    Write-Host "Erro ao criar a conexão VPN: $_"
    Exit
}

# Configura as credenciais da VPN
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

# Salva as credenciais para conexão automática
try {
    cmd.exe /c "rasphone -f `"$env:APPDATA\Microsoft\Network\Connections\Pbk\rasphone.pbk`" -n `"$connectionName`" -u `"$username`" -p `"$password`""
    Write-Host "Credenciais salvas para a conexão '$connectionName'."
} catch {
    Write-Host "Erro ao salvar as credenciais: $_"
}

# Testa a conexão VPN
Write-Host "Tentando conectar à VPN '$connectionName'..."
try {
    rasdial $connectionName $username $password
    Write-Host "Conexão à VPN '$connectionName' estabelecida com sucesso!"
} catch {
    Write-Host "Erro ao conectar à VPN: $_"
}

Write-Host "Configuração concluída. Para conectar manualmente, use o menu de redes ou execute: rasdial `"$connectionName`""
Write-Host "Para desconectar, execute: rasdial `"$connectionName`" /DISCONNECT"