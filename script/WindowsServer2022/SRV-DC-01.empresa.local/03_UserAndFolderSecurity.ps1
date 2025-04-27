# Script para configurar compartilhamentos ocultos de pastas com permissões de leitura/gravação e adicionar usuário Administrador a grupos
# Requisitos: Windows Server 2022, executado como administrador, Active Directory configurado

# Verificar se o script está sendo executado como administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Este script deve ser executado como administrador."
    exit 1
}

# Criar diretório temporário para logs
$logPath = "C:\Temp\UserAndFolderSecurityConfig.log"
if (-not (Test-Path "C:\Temp")) { New-Item -Path "C:\Temp" -ItemType Directory -Force }
function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Write-Host $logMessage
    Add-Content -Path $logPath -Value $logMessage
}

# Verificar se o módulo Active Directory está disponível
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Log "Módulo ActiveDirectory não encontrado. Instale o RSAT-AD-PowerShell."
    exit 1
}

# Carregar o módulo Active Directory
try {
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Log "Módulo ActiveDirectory carregado com sucesso."
} catch {
    Write-Log "Erro ao carregar o módulo ActiveDirectory: $_"
    exit 1
}

# Verificar conectividade com o domínio
$domain = "empresa.local"
try {
    $domainInfo = Get-ADDomain -Identity $domain -ErrorAction Stop
    Write-Log "Conexão com o domínio ${domain} estabelecida."
} catch {
    Write-Log "Erro ao conectar ao domínio ${domain}: $_"
    exit 1
}

# Verificar resolução DNS do domínio
try {
    $dnsTest = Resolve-DnsName -Name $domain -ErrorAction Stop
    Write-Log "Resolução DNS para ${domain} bem-sucedida: $($dnsTest.NameHost)"
} catch {
    Write-Log "Erro ao resolver DNS para ${domain}: $_"
    exit 1
}

# Definir grupos e pastas com compartilhamentos ocultos
$folderConfig = @(
    @{
        Path = "D:\ARQUIVOS\Publico"
        GroupName = "GRP_Publico"
        ShareName = "Publico$" # Compartilhamento oculto
        NTFSRights = "Modify"  # Leitura, escrita, exclusão
        ShareRights = "Change" # Leitura/escrita no compartilhamento
    },
    @{
        Path = "D:\ARQUIVOS\Confidencial"
        GroupName = "GRP_Confidencial"
        ShareName = "Confidencial$" # Compartilhamento oculto
        NTFSRights = "Modify"
        ShareRights = "Change"
    },
    @{
        Path = "D:\ARQUIVOS\Departamentos\RH"
        GroupName = "GRP_RH"
        ShareName = "RH$" # Compartilhamento oculto
        NTFSRights = "Modify"
        ShareRights = "Change"
    },
    @{
        Path = "D:\ARQUIVOS\Departamentos\Financeiro"
        GroupName = "GRP_Financeiro"
        ShareName = "Financeiro$" # Compartilhamento oculto
        NTFSRights = "Modify"
        ShareRights = "Change"
    },
    @{
        Path = "D:\ARQUIVOS\Departamentos\TI"
        GroupName = "GRP_TI"
        ShareName = "TI$" # Compartilhamento oculto
        NTFSRights = "Modify"
        ShareRights = "Change"
    }
)

# 1. Adicionar usuário Administrador aos grupos
$adminUser = "Administrador"
Write-Log "Adicionando usuário ${adminUser} aos grupos de segurança..."
foreach ($config in $folderConfig) {
    $groupName = $config.GroupName
    try {
        $group = Get-ADGroup -Identity $groupName -ErrorAction Stop
        $user = Get-ADUser -Identity $adminUser -ErrorAction Stop
        if (-not (Get-ADGroupMember -Identity $groupName | Where-Object { $_.SamAccountName -eq $adminUser })) {
            Add-ADGroupMember -Identity $groupName -Members $user -ErrorAction Stop
            Write-Log "Usuário ${adminUser} adicionado ao grupo ${groupName}."
            # Aguardar replicação (15 segundos)
            Start-Sleep -Seconds 15
        } else {
            Write-Log "Usuário ${adminUser} já é membro do grupo ${groupName}."
        }
    } catch {
        Write-Log "Erro ao adicionar usuário ${adminUser} ao grupo ${groupName}: $_"
    }
}

# 2. Configurar permissões NTFS e compartilhamentos ocultos
foreach ($config in $folderConfig) {
    $folderPath = $config.Path
    $groupName = $config.GroupName
    $shareName = $config.ShareName
    $ntfsRights = $config.NTFSRights
    $shareRights = $config.ShareRights
    $domainGroup = "empresa\${groupName}"

    # Verificar se a pasta existe
    if (-not (Test-Path $folderPath)) {
        Write-Log "Pasta ${folderPath} não encontrada. Pulando configuração."
        continue
    }

    # Verificar se o grupo existe e obter SID
    try {
        $group = Get-ADGroup -Identity $groupName -ErrorAction Stop
        $groupSid = $group.SID
        Write-Log "Grupo ${groupName} encontrado com SID ${groupSid}."

        # Tentar resolver a identidade do grupo para compartilhamento
        $ntAccount = New-Object System.Security.Principal.NTAccount($domainGroup)
        $resolvedSid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])
        Write-Log "Identidade ${domainGroup} resolvida com SID ${resolvedSid}."
    } catch {
        Write-Log "Grupo ${groupName} não encontrado ou não pode ser resolvido: $_"
        continue
    }

    # 2.1. Configurar permissões NTFS usando SID diretamente
    Write-Log "Configurando permissões NTFS para ${folderPath}..."
    try {
        # Desativar herança e remover permissões existentes
        $acl = Get-Acl -Path $folderPath
        $acl.SetAccessRuleProtection($true, $false)
        $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }

        # Adicionar permissão para o grupo usando SID (leitura, escrita, exclusão)
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($groupSid, $ntfsRights, "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.AddAccessRule($accessRule)

        # Adicionar permissão para administradores
        $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.AddAccessRule($adminRule)

        # Aplicar ACL
        Set-Acl -Path $folderPath -AclObject $acl -ErrorAction Stop
        Write-Log "Permissões NTFS aplicadas em ${folderPath}."
    } catch {
        Write-Log "Erro ao configurar permissões NTFS em ${folderPath}: $_"
    }

    # 2.2. Configurar compartilhamento oculto
    Write-Log "Configurando compartilhamento oculto ${shareName} para ${folderPath}..."
    try {
        # Remover compartilhamento existente, se houver
        if (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue) {
            Remove-SmbShare -Name $shareName -Force -ErrorAction Stop
            Write-Log "Compartilhamento ${shareName} existente removido."
        }

        # Criar novo compartilhamento oculto com permissões de leitura/escrita
        New-SmbShare -Name $shareName -Path $folderPath -Description "Compartilhamento oculto para ${shareName}" -FullAccess "BUILTIN\Administrators" -ChangeAccess $domainGroup -ErrorAction Stop
        Write-Log "Compartilhamento oculto ${shareName} criado com sucesso."

        # Verificar se o compartilhamento foi criado
        if (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue) {
            Write-Log "Verificação: Compartilhamento ${shareName} confirmado."
        } else {
            Write-Log "Erro: Compartilhamento ${shareName} não foi criado corretamente."
        }
    } catch {
        Write-Log "Erro ao configurar compartilhamento oculto ${shareName}: $_"
    }
}

# 3. Mensagem de conclusão
Write-Log "Configuração de usuário e permissões com compartilhamentos ocultos concluída. Log salvo em ${logPath}."