# Script: FixDnsDomain.ps1
# Descrição: Configura o sufixo DNS primário e corrige registros DNS
# Requisitos: Executar como administrador

#Requires -RunAsAdministrator

# Variáveis
$ServerName = "srv-dc-01"
$DomainName = "aguiar.local"  # Domínio ajustado para aguiar.local
$FullServerName = "$ServerName.$DomainName"
$ServerIP = "192.168.2.107"

try {
    # Verifica se o script está sendo executado como administrador
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "Este script deve ser executado como administrador!"
        exit 1
    }

    # Verifica o sufixo DNS atual
    $currentDnsSuffix = (Get-DnsClient).ConnectionSpecificSuffix
    if ($currentDnsSuffix -eq $DomainName) {
        Write-Host "O sufixo DNS primário já está configurado como $DomainName." -ForegroundColor Yellow
    } else {
        # Configura o sufixo DNS primário
        Write-Host "Configurando o sufixo DNS primário como $DomainName..." -ForegroundColor Green
        Set-DnsClient -InterfaceAlias (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).Name -ConnectionSpecificSuffix $DomainName -RegisterThisConnectionsAddress $true -UseSuffixWhenRegistering $true -ErrorAction Stop
        Write-Host "Sufixo DNS primário configurado com sucesso!" -ForegroundColor Green
    }

    # Verifica se o servidor está em um domínio (caso seja um DC)
    $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
    if ($computerSystem.PartOfDomain -and $computerSystem.Domain -ne $DomainName) {
        Write-Warning "O servidor está em um domínio diferente ($($computerSystem.Domain)). Ajuste manualmente se necessário."
    } elseif (-not $computerSystem.PartOfDomain) {
        Write-Host "Associando o servidor ao domínio $DomainName..." -ForegroundColor Green
        Add-Computer -DomainName $DomainName -Restart:$false -ErrorAction Stop
        Write-Host "Servidor associado ao domínio. Reinicialização necessária." -ForegroundColor Green
    }

    # Atualiza os registros DNS (SOA e NS)
    Write-Host "Verificando e atualizando registros DNS..." -ForegroundColor Green
    $zone = Get-DnsServerZone -Name $DomainName -ErrorAction SilentlyContinue
    if ($zone) {
        # Atualiza o registro NS
        $nsRecord = Get-DnsServerResourceRecord -ZoneName $DomainName -RRType "NS" -Name "@" -ErrorAction SilentlyContinue
        if ($nsRecord -and $nsRecord.RecordData.NameServer -ne "$FullServerName.") {
            Remove-DnsServerResourceRecord -ZoneName $DomainName -RRType "NS" -Name "@" -RecordData $nsRecord.RecordData.NameServer -Force -ErrorAction Stop
            Add-DnsServerResourceRecord -ZoneName $DomainName -NS -Name "@" -NameServer "$FullServerName" -ErrorAction Stop
            Write-Host "Registro NS atualizado para $FullServerName." -ForegroundColor Green
        }

        # Verifica o SOA
        $soaRecord = Get-DnsServerResourceRecord -ZoneName $DomainName -RRType "SOA" -ErrorAction SilentlyContinue
        if ($soaRecord -and $soaRecord.RecordData.PrimaryServer -ne "$FullServerName.") {
            Write-Host "Atualizando registro SOA..." -ForegroundColor Green
            Set-DnsServerResourceRecord -ZoneName $DomainName -OldInputObject $soaRecord -NewInputObject ([Microsoft.Management.Infrastructure.CimInstance]::new($soaRecord).PSObject.Copy() | Add-Member -MemberType NoteProperty -Name "PrimaryServer" -Value "$FullServerName." -PassThru -Force) -ErrorAction Stop
            Write-Host "Registro SOA atualizado para $FullServerName." -ForegroundColor Green
        }
    } else {
        Write-Warning "Zona $DomainName não encontrada. Crie a zona manualmente se necessário."
    }

    # Força o registro do servidor no DNS
    Write-Host "Registrando o servidor no DNS..." -ForegroundColor Green
    Register-DnsClient -ErrorAction Stop

    # Testa a configuração
    Write-Host "Testando a resolução DNS..." -ForegroundColor Green
    $testResult = Resolve-DnsName -Name $FullServerName -Server $ServerIP -ErrorAction SilentlyContinue
    if ($testResult) {
        Write-Host "Resolução DNS funcionando corretamente para $FullServerName!" -ForegroundColor Green
    } else {
        Write-Warning "Falha na resolução de $FullServerName. Verifique a configuração."
    }

} catch {
    Write-Error "Erro durante a execução: $($_.Exception.Message)"
    exit 1
}

Write-Host "Configuração concluída. Reinicie o servidor para aplicar todas as alterações." -ForegroundColor Cyan