Try {
    # Define credenciais
    $oldAdmin = "Administrador"
    $newAdmin = "itconnectadm"
    $adminPassword = "96PO08as!@)(%"
    $secureAdminPassword = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force

    # Verifica se o usuário administrador existe
    $adminExists = Get-LocalUser -Name $oldAdmin -ErrorAction SilentlyContinue
    If ($adminExists) {
        # Renomeia o usuário administrador
        Rename-LocalUser -Name $oldAdmin -NewName $newAdmin
        Set-LocalUser -Name $newAdmin -Password $secureAdminPassword
        Enable-LocalUser -Name $newAdmin
        Write-Host "✅ Usuário '$oldAdmin' renomeado para '$newAdmin', senha alterada e ativado."
    } Else {
        Write-Host "⚠️ Usuário '$oldAdmin' não encontrado."
    }
}
Catch {
    Write-Error "❌ Ocorreu um erro: $($_.Exception.Message)"
}
