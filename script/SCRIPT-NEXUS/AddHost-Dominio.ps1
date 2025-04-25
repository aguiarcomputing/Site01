# Parâmetros do domínio
$dominio = "NEXUS.LOCAL"
$usuarioDominio = "itconnectadm"
$senhaTexto = "96PO08as@!!(&(4132"

# Função para limpar variáveis sensíveis
function Clear-SensitiveData {
    $script:senhaTexto = $null
    $script:senhaDominio = $null
    $script:credencial = $null
}

# Função para desconectar sessões de rede
function Clear-NetworkConnections {
    try {
        # Desconecta todas as conexões SMB
        net use * /delete /y | Out-Null
        Write-Host "Conexões de rede existentes desconectadas." -ForegroundColor Cyan
    } catch {
        Write-Host "Aviso: Não foi possível desconectar algumas conexões de rede: $_" -ForegroundColor Yellow
    }
}

try {
    # Converte a senha para SecureString
    $senhaDominio = ConvertTo-SecureString $senhaTexto -AsPlainText -Force

    # Cria o objeto de credencial
    $credencial = New-Object System.Management.Automation.PSCredential("$dominio\$usuarioDominio", $senhaDominio)

    # Obtém o nome atual do computador
    $nomeAtual = $env:COMPUTERNAME

    # Verifica se o computador já está no domínio
    if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {
        Write-Host "O computador já está no domínio. Nome atual: $nomeAtual" -ForegroundColor Yellow
        exit
    }

    # Desconecta conexões de rede existentes
    Clear-NetworkConnections

    # Aguarda brevemente para garantir que as conexões foram limpas
    Start-Sleep -Seconds 5

    # Adiciona o computador ao domínio mantendo o nome atual
    Add-Computer -DomainName $dominio -Credential $credencial -Force -Restart -ErrorAction Stop
    Write-Host "Computador '$nomeAtual' adicionado ao domínio '$dominio' com sucesso. Reiniciando..." -ForegroundColor Green

} catch {
    Write-Host "Erro ao adicionar o computador ao domínio: $_" -ForegroundColor Red
    Write-Host "Detalhes do erro: $($_.Exception.Message)" -ForegroundColor Red

} finally {
    # Limpa variáveis sensíveis
    Clear-SensitiveData
    # Força a coleta de lixo para limpar memória
    [System.GC]::Collect()
}