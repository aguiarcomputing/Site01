# Script para criar zona de pesquisa inversa e registro PTR
# Requer execução com privilégios administrativos

# Parâmetros
$ReverseZoneName = "2.168.192.in-addr.arpa"  # Zona para 192.168.2.0/24
$IPAddress = "192.168.2.254"                 # IP para o registro PTR
$PTRHostName = "srv-dc-01.empresa.local"      # Nome DNS associado ao IP
$DNSServerName = $env:COMPUTERNAME           # Nome do servidor DNS (ou especifique outro)

# 1. Verificar se o serviço DNS está instalado
if (-not (Get-WindowsFeature -Name DNS -ErrorAction SilentlyContinue | Where-Object { $_.InstallState -eq "Installed" })) {
    Write-Host "Serviço DNS não está instalado neste servidor. Instale o DNS Server antes de continuar." -ForegroundColor Red
    exit
}

# 2. Verificar se a zona já existe
$existingZone = Get-DnsServerZone -ComputerName $DNSServerName -Name $ReverseZoneName -ErrorAction SilentlyContinue
if ($existingZone) {
    Write-Host "Zona de pesquisa inversa '$ReverseZoneName' já existe. Continuando para adicionar registro PTR..." -ForegroundColor Yellow
} else {
    # Criar zona de pesquisa inversa primária
    Write-Host "Criando zona de pesquisa inversa '$ReverseZoneName'..." -ForegroundColor Green
    try {
        Add-DnsServerPrimaryZone `
            -ComputerName $DNSServerName `
            -NetworkID "192.168.2.0/24" `
            -ReplicationScope "Domain" `
            -ErrorAction Stop
        Write-Host "Zona '$ReverseZoneName' criada com sucesso!" -ForegroundColor Green
    } catch {
        Write-Host "Erro ao criar zona: $_" -ForegroundColor Red
        exit
    }
}

# 3. Adicionar registro PTR
Write-Host "Adicionando registro PTR para $IPAddress -> $PTRHostName..." -ForegroundColor Green
try {
    Add-DnsServerResourceRecordPtr `
        -ComputerName $DNSServerName `
        -ZoneName $ReverseZoneName `
        -Name "254" `
        -PtrDomainName $PTRHostName `
        -ErrorAction Stop
    Write-Host "Registro PTR criado com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "Erro ao criar registro PTR: $_" -ForegroundColor Red
    exit
}

# 4. Validar configuração
Write-Host "`nValidando configuração..." -ForegroundColor Cyan
$ptrRecord = Get-DnsServerResourceRecord -ComputerName $DNSServerName -ZoneName $ReverseZoneName -RRType Ptr -Name "254" -ErrorAction SilentlyContinue
if ($ptrRecord) {
    Write-Host "Registro PTR encontrado: $IPAddress -> $($ptrRecord.RecordData.PtrDomainName)" -ForegroundColor Green
} else {
    Write-Host "Registro PTR não encontrado. Verifique manualmente." -ForegroundColor Red
}

# 5. Testar resolução inversa
Write-Host "`nTestando resolução inversa com nslookup..." -ForegroundColor Cyan
$result = nslookup $IPAddress $DNSServerName 2>&1
Write-Host ($result | Out-String)