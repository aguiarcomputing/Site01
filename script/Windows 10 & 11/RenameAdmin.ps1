# Script: RenameAdmin.ps1
# Descrição: Ativa, renomeia e atualiza a senha do usuário Administrador

# Verifica se está sendo executado como administrador
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Este script deve ser executado como administrador!" -ForegroundColor Red
    exit 1
}

# Variáveis
$NewAdminName = "aguiaradm"
$NewPassword = "bz07fx$#oela14"

try {
    # Ativa o usuário Administrador (caso esteja desativado)
    Write-Host "Ativando o usuário Administrador..." -ForegroundColor Green
    $adminAccount = Get-LocalUser -Name "Administrador" -ErrorAction Stop
    if (-not $adminAccount.Enabled) {
        Enable-LocalUser -Name "Administrador" -ErrorAction Stop
        Write-Host "Usuário Administrador ativado com sucesso." -ForegroundColor Green
    } else {
        Write-Host "Usuário Administrador já está ativado." -ForegroundColor Yellow
    }

    # Renomeia o usuário Administrador para aguiaradm
    Write-Host "Renomeando Administrador para $NewAdminName..." -ForegroundColor Green
    Rename-LocalUser -Name "Administrador" -NewName $NewAdminName -ErrorAction Stop
    Write-Host "Usuário renomeado para $NewAdminName com sucesso." -ForegroundColor Green

    # Atualiza a senha
    Write-Host "Atualizando a senha do usuário $NewAdminName..." -ForegroundColor Green
    $securePassword = ConvertTo-SecureString $NewPassword -AsPlainText -Force
    Set-LocalUser -Name $NewAdminName -Password $securePassword -ErrorAction Stop
    Write-Host "Senha atualizada com sucesso!" -ForegroundColor Green

} catch {
    Write-Host "Erro durante a execução: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Script concluído com sucesso!" -ForegroundColor Cyan