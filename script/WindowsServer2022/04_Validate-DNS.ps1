# Script para validar e corrigir DNS no servidor SRV-DC-01
# Requer execução com privilégios administrativos

# Parâmetros ajustáveis
$DNSServer = "SRV-DC-01"
$IPAddress = "192.168.2.254"
$DomainName = "empresa.local"              # Ajuste para seu domínio
$ReverseZoneName = "2.168.192.in-addr.arpa" # Zona inversa para 192.168.2.0/24
$NetBIOSName = "EMPRESA"                  # Nome NetBIOS do domínio
$ReplicationScope = "Domain"              # Replicação AD-integrada (Domain ou Forest)

# Função para converter bytes em GB (não usada aqui, mas mantida para expansibilidade)
function Convert-BytesToGB {
    param ([uint64]$Bytes)
    return [math]::Round($Bytes / 1GB, 2)
}

# Função para log
function Write-Log {
    param ($Message, $Color = "White")
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message" -ForegroundColor $Color
}

# 1. Verificar se o servidor DNS está acessível
Write-Log "Verificando conectividade com o servidor DNS $DNSServer ($IPAddress)..." -Color Cyan
if (-not (Test-Connection -ComputerName $DNSServer -Count 2 -Quiet)) {
    Write-Log "Servidor $DNSServer não está respondendo ao ping. Verifique a conectividade." -Color Red
    exit
}

# 2. Verificar se o serviço DNS está instalado e rodando
Write-Log "Verificando serviço DNS..." -Color Cyan
$dnsService = Get-Service -ComputerName $DNSServer -Name DNS -ErrorAction SilentlyContinue
if (-not $dnsService -or $dnsService.Status -ne "Running") {
    Write-Log "Serviço DNS não está instalado ou não está rodando em $DNSServer." -Color Red
    exit
}

# 3. Validar configuração DNS do servidor (deve apontar para si mesmo)
Write-Log "Verificando configuração de DNS do servidor..." -Color Cyan
$dnsClient = Get-DnsClientServerAddress -ComputerName $DNSServer -InterfaceAlias "Ethernet*" -ErrorAction SilentlyContinue
if ($dnsClient.ServerAddresses -notcontains $IPAddress) {
    Write-Log "O servidor não está apontando para si mesmo como DNS primário. Corrigindo..." -Color Yellow
    try {
        Set-DnsClientServerAddress -ComputerName $DNSServer -InterfaceAlias "Ethernet*" -ServerAddresses $IPAddress -ErrorAction Stop
        Write-Log "Configuração de DNS corrigida para $IPAddress." -Color Green
    } catch {
        Write-Log "Erro ao corrigir configuração de DNS: $_" -Color Red
    }
}

# 4. Validar zona de pesquisa direta
Write-Log "Validando zona de pesquisa direta '$DomainName'..." -Color Cyan
$forwardZone = Get-DnsServerZone -ComputerName $DNSServer -Name $DomainName -ErrorAction SilentlyContinue
if (-not $forwardZone) {
    Write-Log "Zona '$DomainName' não encontrada. Criando zona AD-integrada..." -Color Yellow
    try {
        Add-DnsServerPrimaryZone `
            -ComputerName $DNSServer `
            -Name $DomainName `
            -ReplicationScope $ReplicationScope `
            -DynamicUpdate "Secure" `
            -ErrorAction Stop
        Write-Log "Zona '$DomainName' criada com sucesso!" -Color Green
    } catch {
        Write-Log "Erro ao criar zona direta: $_" -Color Red
        exit
    }
} else {
    # Verificar configurações da zona
    if ($forwardZone.IsDsIntegrated -ne $true) {
        Write-Log "Zona '$DomainName' não é AD-integrada. Convertendo..." -Color Yellow
        try {
            ConvertTo-DnsServerPrimaryZone -Name $DomainName -ReplicationScope $ReplicationScope -Force -ErrorAction Stop
            Write-Log "Zona convertida para AD-integrada." -Color Green
        } catch {
            Write-Log "Erro ao converter zona: $_" -Color Red
        }
    }
    if ($forwardZone.DynamicUpdate -ne "Secure") {
        Write-Log "Zona '$DomainName' não usa atualizações dinâmicas seguras. Corrigindo..." -Color Yellow
        try {
            Set-DnsServerPrimaryZone -ComputerName $DNSServer -Name $DomainName -DynamicUpdate "Secure" -ErrorAction Stop
            Write-Log "Atualizações dinâmicas seguras habilitadas." -Color Green
        } catch {
            Write-Log "Erro ao configurar atualizações dinâmicas: $_" -Color Red
        }
    }
}

# 5. Validar registro A para o DC
Write-Log "Validando registro A para $DNSServer.$DomainName..." -Color Cyan
$aRecord = Get-DnsServerResourceRecord -ComputerName $DNSServer -ZoneName $DomainName -Name $DNSServer -RRType A -ErrorAction SilentlyContinue
if (-not $aRecord -or $aRecord.RecordData.IPv4Address -ne $IPAddress) {
    Write-Log "Registro A para $DNSServer.$DomainName está ausente ou incorreto. Corrigindo..." -Color Yellow
    try {
        if ($aRecord) { Remove-DnsServerResourceRecord -ComputerName $DNSServer -ZoneName $DomainName -RRType A -Name $DNSServer -Force }
        Add-DnsServerResourceRecordA `
            -ComputerName $DNSServer `
            -ZoneName $DomainName `
            -Name $DNSServer `
            -IPv4Address $IPAddress `
            -ErrorAction Stop
        Write-Log "Registro A criado para $DNSServer.$DomainName -> $IPAddress." -Color Green
    } catch {
        Write-Log "Erro ao corrigir registro A: $_" -Color Red
    }
}

# 6. Validar registros SRV
Write-Log "Validando registros SRV essenciais..." -Color Cyan
$requiredSRVs = @(
    "_ldap._tcp.$DomainName",
    "_kerberos._tcp.$DomainName",
    "_ldap._tcp.dc._msdcs.$DomainName",
    "_kerberos._tcp.dc._msdcs.$DomainName"
)
foreach ($srv in $requiredSRVs) {
    $srvRecord = Resolve-DnsName -Name $srv -Server $IPAddress -Type SRV -ErrorAction SilentlyContinue
    if (-not $srvRecord) {
        Write-Log "Registro SRV $srv está ausente. Tentando recriar registros AD..." -Color Yellow
        try {
            # Forçar re-registro de registros DNS do DC
            ipconfig /registerdns
            Restart-Service -Name DNS -Force
            Write-Log "Comando de re-registro executado. Verifique novamente após alguns minutos." -Color Yellow
        } catch {
            Write-Log "Erro ao tentar recriar registros SRV: $_" -Color Red
        }
    } else {
        Write-Log "Registro SRV $srv encontrado." -Color Green
    }
}

# 7. Validar zona de pesquisa inversa
Write-Log "Validando zona de pesquisa inversa '$ReverseZoneName'..." -Color Cyan
$reverseZone = Get-DnsServerZone -ComputerName $DNSServer -Name $ReverseZoneName -ErrorAction SilentlyContinue
if (-not $reverseZone) {
    Write-Log "Zona '$ReverseZoneName' não encontrada. Criando zona AD-integrada..." -Color Yellow
    try {
        Add-DnsServerPrimaryZone `
            -ComputerName $DNSServer `
            -NetworkID "192.168.2.0/24" `
            -ReplicationScope $ReplicationScope `
            -DynamicUpdate "Secure" `
            -ErrorAction Stop
        Write-Log "Zona '$ReverseZoneName' criada com sucesso!" -Color Green
    } catch {
        Write-Log "Erro ao criar zona inversa: $_" -Color Red
    }
} else {
    if ($reverseZone.IsDsIntegrated -ne $true) {
        Write-Log "Zona '$ReverseZoneName' não é AD-integrada. Convertendo..." -Color Yellow
        try {
            ConvertTo-DnsServerPrimaryZone -Name $ReverseZoneName -ReplicationScope $ReplicationScope -Force -ErrorAction Stop
            Write-Log "Zona inversa convertida para AD-integrada." -Color Green
        } catch {
            Write-Log "Erro ao converter zona inversa: $_" -Color Red
        }
    }
}

# 8. Validar registro PTR
Write-Log "Validando registro PTR para $IPAddress..." -Color Cyan
$ptrRecord = Get-DnsServerResourceRecord -ComputerName $DNSServer -ZoneName $ReverseZoneName -Name "254" -RRType Ptr -ErrorAction SilentlyContinue
if (-not $ptrRecord -or $ptrRecord.RecordData.PtrDomainName -ne "$DNSServer.$DomainName.") {
    Write-Log "Registro PTR para $IPAddress está ausente ou incorreto. Corrigindo..." -Color Yellow
    try {
        if ($ptrRecord) { Remove-DnsServerResourceRecord -ComputerName $DNSServer -ZoneName $ReverseZoneName -RRType Ptr -Name "254" -Force }
        Add-DnsServerResourceRecordPtr `
            -ComputerName $DNSServer `
            -ZoneName $ReverseZoneName `
            -Name "254" `
            -PtrDomainName "$DNSServer.$DomainName" `
            -ErrorAction Stop
        Write-Log "Registro PTR criado para $IPAddress -> $DNSServer.$DomainName." -Color Green
    } catch {
        Write-Log "Erro ao corrigir registro PTR: $_" -Color Red
    }
}

# 9. Configurar boas práticas (Scavenging, TTL, etc.)
Write-Log "Aplicando boas práticas de DNS..." -Color Cyan
try {
    # Habilitar scavenging na zona direta
    Set-DnsServerZoneAging `
        -ComputerName $DNSServer `
        -Name $DomainName `
        -Aging $true `
        -RefreshInterval 7.00:00:00 `
        -NoRefreshInterval 7.00:00:00 `
        -ErrorAction Stop
    Write-Log "Scavenging habilitado na zona '$DomainName' (7 dias)." -Color Green

    # Habilitar scavenging na zona inversa
    Set-DnsServerZoneAging `
        -ComputerName $DNSServer `
        -Name $ReverseZoneName `
        -Aging $true `
        -RefreshInterval 7.00:00:00 `
        -NoRefreshInterval 7.00:00:00 `
        -ErrorAction Stop
    Write-Log "Scavenging habilitado na zona '$ReverseZoneName' (7 dias)." -Color Green

    # Configurar scavenging no servidor
    Set-DnsServerScavenging `
        -ComputerName $DNSServer `
        -ScavengingInterval 7.00:00:00 `
        -ErrorAction Stop
    Write-Log "Scavenging no servidor configurado (7 dias)." -Color Green
} catch {
    Write-Log "Erro ao configurar boas práticas: $_" -Color Red
}

# 10. Executar testes diagnósticos
Write-Log "Executando testes diagnósticos..." -Color Cyan

# Teste com nslookup (resolução direta e inversa)
Write-Log "Testando resolução direta ($DNSServer.$DomainName)..." -Color Cyan
$resultForward = nslookup "$DNSServer.$DomainName" $IPAddress 2>&1
Write-Log ($resultForward | Out-String) -Color White

Write-Log "Testando resolução inversa ($IPAddress)..." -Color Cyan
$resultReverse = nslookup $IPAddress $IPAddress 2>&1
Write-Log ($resultReverse | Out-String) -Color White

# Teste com dcdiag
Write-Log "Executando dcdiag para testes de DNS..." -Color Cyan
$dcdiagResult = dcdiag /test:DNS /s:$DNSServer
Write-Log ($dcdiagResult | Out-String) -Color White

# 11. Resumo final
Write-Log "Validação e configuração concluídas!" -Color Green
Write-Log "Resumo:" -Color Cyan
Write-Log "- Zona direta: $(if ($forwardZone) { 'Configurada' } else { 'Criada' })" -Color White
Write-Log "- Zona inversa: $(if ($reverseZone) { 'Configurada' } else { 'Criada' })" -Color White
Write-Log "- Registro A: $(if ($aRecord) { 'Validado' } else { 'Corrigido' })" -Color White
Write-Log "- Registro PTR: $(if ($ptrRecord) { 'Validado' } else { 'Corrigido' })" -Color White
Write-Log "- Boas práticas: Scavenging habilitado, atualizações dinâmicas seguras configuradas." -Color White
Write-Log "Verifique os testes acima para confirmar a saúde do DNS." -Color Yellow