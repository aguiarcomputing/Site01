# Script para analisar discos, calcular tamanho total e criar partição BACKUP
# Requer execução com privilégios administrativos

# Função para converter bytes em GB
function Convert-BytesToGB {
    param ([uint64]$Bytes)
    return [math]::Round($Bytes / 1GB, 2)
}

# 1. Analisar todos os discos instalados
Write-Host "Analisando discos instalados..." -ForegroundColor Green
$disks = Get-Disk
$totalSize = 0
$diskDetails = @()

foreach ($disk in $disks) {
    $totalSize += $disk.Size
    $diskDetails += [PSCustomObject]@{
        DiskNumber      = $disk.Number
        FriendlyName    = $disk.FriendlyName
        SizeGB          = Convert-BytesToGB -Bytes $disk.Size
        PartitionStyle  = $disk.PartitionStyle
        IsSystemDisk    = $disk.IsSystem
        IsOffline       = $disk.IsOffline
    }
}

# Exibir detalhes dos discos
Write-Host "`nDetalhes dos discos:" -ForegroundColor Cyan
$diskDetails | Format-Table -AutoSize
Write-Host "Tamanho total de todos os discos: $(Convert-BytesToGB -Bytes $totalSize) GB" -ForegroundColor Yellow

# 2. Análise dinâmica e particionamento
Write-Host "`nIniciando análise dinâmica e particionamento..." -ForegroundColor Green
foreach ($disk in $disks) {
    # Ignorar discos offline, do sistema ou inicializados incorretamente
    if ($disk.IsOffline) {
        Write-Host "Disco $($disk.Number) está offline. Ignorando..." -ForegroundColor Red
        continue
    }
    if ($disk.IsSystem) {
        Write-Host "Disco $($disk.Number) é disco do sistema. Ignorando..." -ForegroundColor Red
        continue
    }
    if ($disk.PartitionStyle -eq "RAW") {
        # Inicializar disco RAW como GPT
        Write-Host "Inicializando disco $($disk.Number) como GPT..." -ForegroundColor Yellow
        Initialize-Disk -Number $disk.Number -PartitionStyle GPT -Confirm:$false
    } elseif ($disk.PartitionStyle -ne "GPT") {
        Write-Host "Disco $($disk.Number) não é GPT. Ignorando..." -ForegroundColor Red
        continue
    }

    # Verificar espaço disponível
    $partitions = Get-Partition -DiskNumber $disk.Number -ErrorAction SilentlyContinue
    $usedSpace = ($partitions | Measure-Object -Property Size -Sum).Sum
    $freeSpace = $disk.Size - $usedSpace
    $freeSpaceGB = Convert-BytesToGB -Bytes $freeSpace

    if ($freeSpace -le 1GB) {
        Write-Host "Disco $($disk.Number) não tem espaço livre suficiente (<1GB). Ignorando..." -ForegroundColor Red
        continue
    }

    # Calcular metade do espaço livre para a partição BACKUP
    $backupSize = [math]::Floor($freeSpace / 2)
    $backupSizeGB = Convert-BytesToGB -Bytes $backupSize

    Write-Host "Disco $($disk.Number): Espaço livre = $freeSpaceGB GB. Criando partição BACKUP com $backupSizeGB GB..." -ForegroundColor Yellow

    # Criar partição BACKUP
    try {
        $newPartition = New-Partition -DiskNumber $disk.Number -Size $backupSize -AssignDriveLetter
        # Formatar partição como NTFS com rótulo BACKUP
        $newPartition | Format-Volume -FileSystem NTFS -NewFileSystemLabel "BACKUP" -Confirm:$false
        Write-Host "Partição BACKUP criada com sucesso no disco $($disk.Number)!" -ForegroundColor Green
    } catch {
        Write-Host "Erro ao criar partição no disco $($disk.Number): $_" -ForegroundColor Red
    }
}

# 3. Resumo final
Write-Host "`nAnálise e particionamento concluídos!" -ForegroundColor Cyan
$updatedDisks = Get-Disk
$updatedDetails = @()

foreach ($disk in $updatedDisks) {
    $partitions = Get-Partition -DiskNumber $disk.Number -ErrorAction SilentlyContinue
    $backupPartition = $partitions | Where-Object { $_.DriveLetter -and (Get-Volume -Partition $_).FileSystemLabel -eq "BACKUP" }
    $backupInfo = if ($backupPartition) { "Sim (Letra: $($backupPartition.DriveLetter):)" } else { "Não" }

    $updatedDetails += [PSCustomObject]@{
        DiskNumber      = $disk.Number
        FriendlyName    = $disk.FriendlyName
        SizeGB          = Convert-BytesToGB -Bytes $disk.Size
        PartitionStyle  = $disk.PartitionStyle
        HasBackup       = $backupInfo
    }
}

Write-Host "`nEstado final dos discos:" -ForegroundColor Cyan
$updatedDetails | Format-Table -AutoSize
Write-Host "Tamanho total de todos os discos: $(Convert-BytesToGB -Bytes ($updatedDisks | Measure-Object -Property Size -Sum).Sum) GB" -ForegroundColor Yellow