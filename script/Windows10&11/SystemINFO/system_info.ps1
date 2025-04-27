# Script para verificar configurações e listar informações do sistema, salvando em C:\

# Definir caminho e nome do arquivo de saída com data e hora
$outputFile = "C:\system_info_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Função para escrever no console e no arquivo
function Write-OutputAndFile {
    param ([string]$text)
    Write-Host $text
    $text | Out-File -FilePath $outputFile -Append
}

# 1. Verificar política de execução de scripts
Write-OutputAndFile "=== Verificando política de execução de scripts ==="
$currentPolicy = Get-ExecutionPolicy
Write-OutputAndFile "Política atual: $currentPolicy"

# Habilitar execução de scripts se estiver restrita (necessita de permissão de administrador)
if ($currentPolicy -eq "Restricted") {
    Write-OutputAndFile "Política restrita detectada. Tentando alterar para RemoteSigned..."
    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Write-OutputAndFile "Política alterada com sucesso para RemoteSigned."
    } catch {
        Write-OutputAndFile "Erro ao alterar política. Execute como administrador."
    }
} else {
    Write-OutputAndFile "A execução de scripts já está habilitada."
}

# 2. Listar programas instalados
Write-OutputAndFile "`n=== Programas instalados ==="
$installedPrograms = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
    Where-Object { $_.DisplayName } | 
    Select-Object DisplayName, DisplayVersion, Publisher
$installedPrograms | Format-Table -AutoSize | Out-String | ForEach-Object { Write-OutputAndFile $_ }

# 3. Verificar modelo do computador e número de série
Write-OutputAndFile "`n=== Informações do sistema ==="
$model = (Get-WmiObject -Class Win32_ComputerSystem).Model
$serial = (Get-WmiObject -Class Win32_BIOS).SerialNumber
Write-OutputAndFile "Modelo do computador: $model"
Write-OutputAndFile "Número de série: $serial"

# 4. Listar usuários criados
Write-OutputAndFile "`n=== Usuários locais ==="
$users = Get-LocalUser | Select-Object Name, Enabled
$users | Format-Table -AutoSize | Out-String | ForEach-Object { Write-OutputAndFile $_ }

Write-OutputAndFile "Script concluído."
Write-Host "Informações salvas em: $outputFile"