Try {
    # Define credenciais
    $oldAdmin = "Administrador"
    $newAdmin = "itconnectadm"
    $adminPassword = "96PO08as!@)(%"
    $secureAdminPassword = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force
    
    $username = "nexusadm"
    $password = "Nexu$@098"
    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    
    # Renomeia o usuário Administrador
    $adminExists = Get-LocalUser -Name $oldAdmin -ErrorAction SilentlyContinue
    If ($adminExists) {
        Rename-LocalUser -Name $oldAdmin -NewName $newAdmin
        Set-LocalUser -Name $newAdmin -Password $secureAdminPassword
        Enable-LocalUser -Name $newAdmin
        Write-Host "Usuário $oldAdmin renomeado para $newAdmin, senha alterada e ativado."
    } Else {
        Write-Host "Usuário $oldAdmin não encontrado."
    }
    
    # Verifica se o usuário nexusadm já existe
    $userExists = Get-LocalUser -Name $username -ErrorAction SilentlyContinue
    
    If (-not $userExists) {
        # Cria o usuário local
        New-LocalUser -Name $username -Password $securePassword -FullName "Nexus Admin" -Description "Usuário administrador criado via script"
        
        # Adiciona o usuário ao grupo de Administradores
        Add-LocalGroupMember -Group "Administradores" -Member $username
        
        Write-Host "Usuário $username criado com sucesso e adicionado ao grupo de Administradores."
    } Else {
        Write-Host "Usuário $username já existe. Nenhuma ação foi realizada."
    }
} Catch {
    Write-Host "Ocorreu um erro: $_"
}
