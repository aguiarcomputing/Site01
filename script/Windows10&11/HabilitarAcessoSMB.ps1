# Script para habilitar acesso sem autenticação a compartilhamentos SMB no Windows 11

# Verifica se o script está sendo executado com privilégios administrativos
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Este script precisa ser executado como administrador. Iniciando com privilégios elevados..."
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Exit
}

# Caminho do Registro
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
$regName = "AllowInsecureGuestAuth"
$regValue = 1

# Verifica se o valor já existe
if (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue) {
    Write-Host "O valor $regName já existe. Verificando o valor atual..."
    $currentValue = (Get-ItemProperty -Path $regPath -Name $regName).$regName
    if ($currentValue -eq $regValue) {
        Write-Host "O valor $regName já está configurado como $regValue. Nenhuma alteração necessária."
    } else {
        Write-Host "Atualizando o valor $regName para $regValue..."
        Set-ItemProperty -Path $regPath -Name $regName -Value $regValue
        Write-Host "Valor atualizado com sucesso."
    }
} else {
    Write-Host "Criando o valor $regName com valor $regValue..."
    New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType DWORD
    Write-Host "Valor criado com sucesso."
}

# Solicita reinicialização
Write-Host "As alterações foram aplicadas. É necessário reiniciar o computador para que tenham efeito."
$restart = Read-Host "Deseja reiniciar o computador agora? (S/N)"
if ($restart -eq "S" -or $restart -eq "s") {
    Write-Host "Reiniciando o computador..."
    Restart-Computer -Force
} else {
    Write-Host "Por favor, reinicie o computador manualmente para aplicar as alterações."
}