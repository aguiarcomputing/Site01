# Script: BloquearRoblox.ps1
# Objetivo: Bloquear o acesso ao Roblox editando o arquivo hosts

# Caminho do arquivo hosts
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"

# Domínios do Roblox a serem bloqueados
$robloxDomains = @(
    "roblox.com",
    "www.roblox.com",
    "api.roblox.com",
    "clientsettingscdn.roblox.com",
    "setup.roblox.com"
)

# Endereço de loopback para bloqueio
$blockIP = "127.0.0.1"

# Verifica se o script está sendo executado como administrador
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Erro: Este script precisa ser executado como administrador." -ForegroundColor Red
    exit
}

# Lê o conteúdo atual do arquivo hosts
$hostsContent = Get-Content -Path $hostsPath

# Adiciona cada domínio à lista, se ainda não estiver presente
foreach ($domain in $robloxDomains) {
    $entry = "$blockIP $domain"
    if ($hostsContent -notcontains $entry) {
        Add-Content -Path $hostsPath -Value $entry
        Write-Host "Bloqueado: $domain" -ForegroundColor Green
    } else {
        Write-Host "Ja bloqueado: $domain" -ForegroundColor Yellow
    }
}

# Limpa o cache de DNS para aplicar as mudanças imediatamente
ipconfig /flushdns | Out-Null
Write-Host "Cache de DNS limpo. O Roblox foi bloqueado com sucesso!" -ForegroundColor Green