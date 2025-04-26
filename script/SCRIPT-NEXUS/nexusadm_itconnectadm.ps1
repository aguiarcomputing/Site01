Try {
    # Define credenciais
    $oldAdmin = "Administrador"
    $newAdmin = "itConnectADM"
    $adminPassword = "996PO08as@!!(&(4132"
    $secureAdminPassword = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force
    
    # Credenciais Nexus
    #$usernameN = "nexus"
    #$passwordN = "Nexus@1"
    #$securePasswordN = ConvertTo-SecureString -String $passwordN -AsPlainText -Force

    # Credenciais NexusAdm
    $usernameA = "nexusadm"
    $passwordA = "Nexu$@098"
    $securePasswordA = ConvertTo-SecureString -String $passwordA -AsPlainText -Force
    
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
    
    # Verifica se o usuário NexusAdm já existe
    $userExistsA = Get-LocalUser -Name $usernameA -ErrorAction SilentlyContinue
    If (-not $userExistsA) {
        # Cria o usuário local
        New-LocalUser -Name $usernameA -Password $securePasswordA -FullName "nexusadmin" -Description "Usuário Administrador criado via script"
        
        # Adiciona o usuário ao grupo de Administradores
        Add-LocalGroupMember -Group "Administradores" -Member $usernameA
        
        Write-Host "Usuário $usernameA criado com sucesso e adicionado ao grupo de Administradores."
    } Else {
        Write-Host "Usuário $usernameA já existe. Nenhuma ação foi realizada."
    }

    # Verifica se o usuário Nexus já existe
    #$userExistsN = Get-LocalUser -Name $usernameN -ErrorAction SilentlyContinue
    #If (-not $userExistsN) {
        # Cria o usuário local
    #    New-LocalUser -Name $usernameN -Password $securePasswordN -FullName "Nexus" -Description "Usuário criado via script"
        
    #    Write-Host "Usuário $usernameN criado com sucesso."
    #} Else {
    #    Write-Host "Usuário $usernameN já existe. Nenhuma ação foi realizada."
    #}

} Catch {
    Write-Host "Ocorreu um erro: $($_.Exception.Message)"
}
