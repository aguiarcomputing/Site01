# Script: Configuração do Servidor DNS para Controlador de Domínio - Windows Server 2022
# Descrição: Configura um servidor DNS primário com zonas direta e inversa, integrado ao Active Directory.

# Verifica privilégios
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Execute este script como administrador!" -ForegroundColor Red
    Exit 1
}

# Variáveis
$IPAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).Name).IPAddress
$Subnet = ($IPAddress.Split('.')[0..2] -join '.') + '.0'
$DomainName = (Get-ADDomain).DNSRoot
$ReverseZone = ($Subnet.Split('.')[0..2] -join '.') + ".in-addr.arpa"
$SubnetMask = Read-Host "Enter subnet mask (e.g., 24 for /24)"
$LogFile = "$env:TEMP\DNS_Setup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$Success = $true

# Cria diretório de logs
$LogDir = "$env:TEMP\Logs"
if (-not (Test-Path $LogDir)) {
    try {
        New-Item -ItemType Directory -Path $LogDir -Force -ErrorAction Stop | Out-Null
    } catch {
        Write-Host "Erro ao criar diretório de logs: $_" -ForegroundColor Red
        $LogFile = "$env:TEMP\DNS_Setup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    }
}
Start-Transcript -Path $LogFile

# Valida variáveis
if (-not ($IPAddress -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$')) {
    Write-Host "Endereço IP inválido: $IPAddress" -ForegroundColor Red
    $Success = $false
    Stop-Transcript
    Exit 1
}
if (-not ($DomainName -match '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')) {
    Write-Host "Nome de domínio inválido: $DomainName" -ForegroundColor Red
    $Success = $false
    Stop-Transcript
    Exit 1
}

# Instala o recurso DNS
if (-not (Get-WindowsFeature -Name DNS).Installed) {
    Write-Host "Instalando o serviço DNS..."
    try {
        $InstallResult = Install-WindowsFeature -Name DNS -IncludeManagementTools -ErrorAction Stop
        if (-not $InstallResult.Success) {
            Write-Host "Falha ao instalar o serviço DNS." -ForegroundColor Red
            $Success = $false
        }
    } catch {
        Write-Host "Erro ao instalar o serviço DNS: $_" -ForegroundColor Red
        $Success = $false
    }
} else {
    Write-Host "Serviço DNS já instalado."
}

# Configura o servidor como DNS primário
Write-Host "Configurando o servidor como DNS primário..."
$Interfaces = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
foreach ($Interface in $Interfaces) {
    Set-DnsClientServerAddress -InterfaceAlias $Interface.Name -ServerAddresses $IPAddress
}

# Configura forwarders
$Forwarders = Read-Host "Enter DNS forwarder IPs (comma-separated, e.g., 8.8.8.8,8.8.4.4)"
Write-Host "Configurando forwarders DNS..."
try {
    Set-DnsServerForwarder -IPAddress ($Forwarders -split ',') -ErrorAction Stop
} catch {
    Write-Host "Erro ao configurar forwarders: $_" -ForegroundColor Yellow
}

# Cria zona primária integrada ao AD
if (-not (Get-DnsServerZone -Name $DomainName -ErrorAction SilentlyContinue)) {
    Write-Host "Criando zona primária integrada ao AD para $DomainName..."
    try {
        Add-DnsServerPrimaryZone -Name $DomainName -ReplicationScope Domain -DynamicUpdate Secure -ErrorAction Stop
        Set-DnsServerZoneAging -Name $DomainName -Aging $true -RefreshInterval 7.00:00:00 -NoRefreshInterval 7.00:00:00
    } catch {
        Write-Host "Erro ao criar zona primária: $_" -ForegroundColor Red
        $Success = $false
    }
} else {
    Write-Host "Zona $DomainName já existe."
}

# Cria zona de pesquisa inversa
if (-not (Get-DnsServerZone -Name $ReverseZone -ErrorAction SilentlyContinue)) {
    Write-Host "Criando zona de pesquisa inversa para $ReverseZone..."
    try {
        Add-DnsServerPrimaryZone -NetworkID "$Subnet/$SubnetMask" -ReplicationScope Domain -DynamicUpdate Secure -ErrorAction Stop
    } catch {
        Write-Host "Erro ao criar zona inversa: $_" -ForegroundColor Red
        $Success = $false
    }
} else {
    Write-Host "Zona inversa $ReverseZone já existe."
}

# Configura registros A e PTR
Write-Host "Definindo $IPAddress como DNS primário da zona $DomainName..."
try {
    Add-DnsServerResourceRecordA -Name "@" -ZoneName $DomainName -IPv4Address $IPAddress -TimeToLive 01:00:00 -ErrorAction Stop
} catch {
    Write-Host "Erro ao adicionar registro A: $_" -ForegroundColor Red
    $Success = $false
}

$HostPart = $IPAddress.Split('.')[-1]
Write-Host "Criando registro PTR para $IPAddress na zona $ReverseZone..."
try {
    Add-DnsServerResourceRecordPtr -Name $HostPart -ZoneName $ReverseZone -PtrDomainName "$DomainName" -TimeToLive 01:00:00 -ErrorAction Stop
} catch {
    Write-Host "Erro ao adicionar registro PTR: $_" -ForegroundColor Red
    $Success = $false
}

# Testa a configuração
Write-Host "Testando resolução do domínio local ($DomainName)..."
$LocalTest = Resolve-DnsName -Name $DomainName -Server $IPAddress -ErrorAction SilentlyContinue
if ($LocalTest) {
    Write-Host "Resolução do domínio local ($DomainName) bem-sucedida!" -ForegroundColor Green
} else {
    Write-Host "Falha ao resolver $DomainName. Verifique a configuração da zona." -ForegroundColor Red
    $Success = $false
}

Write-Host "Testando resolução inversa ($IPAddress)..."
$ReverseTest = Resolve-DnsName -Name $IPAddress -Server $IPAddress -ErrorAction SilentlyContinue
if ($ReverseTest -and $ReverseTest.NameHost -eq $DomainName) {
    Write-Host "Resolução inversa ($IPAddress) bem-sucedida!" -ForegroundColor Green
} else {
    Write-Host "Falha ao resolver $IPAddress. Verifique a zona inversa." -ForegroundColor Red
    $Success = $false
}

Write-Host "Testando resolução externa (google.com)..."
$ExternalTest = Resolve-DnsName -Name "google.com" -Server $IPAddress -ErrorAction SilentlyContinue
if ($ExternalTest) {
    Write-Host "Resolução externa (google.com) bem-sucedida!" -ForegroundColor Green
} else {
    Write-Host "Falha ao resolver google.com. Verifique forwarders ou firewall." -ForegroundColor Yellow
}

# Mensagem final
if ($Success) {
    Write-Host "Servidor DNS primário configurado com sucesso!" -ForegroundColor Green
    Stop-Transcript
    Exit 0
} else {
    Write-Host "Configuração concluída com erros. Verifique os logs em $LogFile." -ForegroundColor Red
    Stop-Transcript
    Exit 1
}