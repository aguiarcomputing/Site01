# Script para verificação do sistema
Write-Host "=== Relatorio de Verificacao do Sistema ===" -ForegroundColor Green

# 1. Verifica usuarios locais configurados
Write-Host "`n1. Usuarios Locais Configurados:" -ForegroundColor Yellow
$localUsers = Get-LocalUser | Where-Object { $_.Enabled -eq $true }
foreach ($user in $localUsers) {
    Write-Host " - Nome: $($user.Name) | Tipo: $($user.PrincipalSource)"
}

# 2. Verifica se todos os drivers foram instalados
Write-Host "`n2. Status dos Drivers:" -ForegroundColor Yellow
$drivers = Get-WmiObject Win32_PnPSignedDriver | Where-Object {$_.DeviceName -ne $null}
$problemDrivers = $drivers | Where-Object {$_.Status -ne "OK"}
if ($problemDrivers) {
    Write-Host "Drivers com problemas encontrados:" -ForegroundColor Red
    $problemDrivers | ForEach-Object { Write-Host " - $($_.DeviceName)" }
} else {
    Write-Host "Todos os drivers parecem estar instalados corretamente" -ForegroundColor Green
}

# 3. Verifica se Desfragmentar e Otimizar Unidades esta desabilitado
Write-Host "`n3. Status da Desfragmentacao:" -ForegroundColor Yellow
$defragStatus = Get-ScheduledTask -TaskName "ScheduledDefrag" -ErrorAction SilentlyContinue
if ($defragStatus -and $defragStatus.State -eq "Disabled") {
    Write-Host "Desfragmentacao esta desabilitada" -ForegroundColor Green
} else {
    Write-Host "Desfragmentacao esta habilitada" -ForegroundColor Red
}

# 4. Versao do Windows
Write-Host "`n4. Versao do Windows:" -ForegroundColor Yellow
$os = Get-CimInstance -ClassName Win32_OperatingSystem
Write-Host "Versao: $($os.Caption)"
Write-Host "Build: $($os.BuildNumber)"
Write-Host "Ultima inicializacao: $($os.LastBootUpTime)"

# 5. Verifica status do Windows Update
Write-Host "`n5. Status do Windows Update:" -ForegroundColor Yellow
try {
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $historyCount = $updateSearcher.GetTotalHistoryCount()
    $lastUpdate = $updateSearcher.QueryHistory(0,1) | Select-Object -First 1
    Write-Host "Ultima atualizacao instalada: $($lastUpdate.Date)"
} catch {
    Write-Host "Nao foi possivel verificar o Windows Update" -ForegroundColor Red
}

# 6. Programas instalados
Write-Host "`n6. Programas Instalados:" -ForegroundColor Yellow
$installedApps = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
    Where-Object { $_.DisplayName -ne $null } | 
    Select-Object DisplayName, DisplayVersion
foreach ($app in $installedApps) {
    Write-Host " - $($app.DisplayName) $($app.DisplayVersion)"
}

# 7. Serial Number e Modelo do Computador
Write-Host "`n7. Informacoes do Hardware:" -ForegroundColor Yellow
$computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem
$biosInfo = Get-CimInstance -ClassName Win32_BIOS
Write-Host "Modelo: $($computerInfo.Model)"
Write-Host "Serial Number: $($biosInfo.SerialNumber)"
Write-Host "Fabricante: $($computerInfo.Manufacturer)"

# 8. Verifica se o Windows esta ativado
Write-Host "`n8. Status de Ativacao do Windows:" -ForegroundColor Yellow
$licenseStatus = (Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "Name like 'Windows%'" | 
    Where-Object { $_.PartialProductKey } | 
    Select-Object -First 1).LicenseStatus
if ($licenseStatus -eq 1) {
    Write-Host "Windows esta ativado" -ForegroundColor Green
} else {
    Write-Host "Windows nao esta ativado" -ForegroundColor Red
}

# 9. Verifica se o Office esta ativado
Write-Host "`n9. Status de Ativacao do Office:" -ForegroundColor Yellow
$officePath = "C:\Program Files (x86)\Microsoft Office\root\Office*"
if (Test-Path $officePath) {
    try {
        $officeLicense = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "Name like 'Office%'" | 
            Where-Object { $_.PartialProductKey } | 
            Select-Object -First 1
        if ($officeLicense.LicenseStatus -eq 1) {
            Write-Host "Office esta ativado" -ForegroundColor Green
        } else {
            Write-Host "Office nao esta ativado" -ForegroundColor Red
        }
    } catch {
        Write-Host "Nao foi possivel verificar a ativacao do Office" -ForegroundColor Yellow
    }
} else {
    Write-Host "Office nao detectado no sistema" -ForegroundColor Yellow
}

Write-Host "`n=== Fim do Relatorio ===" -ForegroundColor Green