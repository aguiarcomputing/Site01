# Script para configurar grupos de segurança e permissões em pastas no servidor SRV-DC-01.empresa.local
# Requisitos: Windows Server 2022, executado como administrador, Active Directory configurado

# Verificar se o script está sendo executado como administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Este script deve ser executado como administrador."
    exit 1
}

# Criar diretório temporário para logs
$logPath = "C:\Temp\FolderSecurityConfig.log"
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

# Definir pastas e configurações de segurança
$folderConfig = @(
    @{
        Path = "D:\ARQUIVOS\Publico"
        GroupName = "GRP_Publico"
        ShareName = "Publico"
        NTFSRights = "ReadAndExecute"
        ShareRights = "Read"
    },
    @{
        Path = "D:\ARQUIVOS\Confidencial"
        GroupName = "GRP_Confidencial"
        ShareName = "Confidencial"
        NTFSRights = "Modify"
        ShareRights = "Change"
    },
    @{
        Path = "D:\ARQUIVOS\Departamentos\RH"
        GroupName = "GRP_RH"
        ShareName = "RH"
        NTFSRights = "Modify"
        ShareRights = "Change"
    },
    @{
        Path = "D:\ARQUIVOS\Departamentos\Financeiro"
        GroupName = "GRP_Financeiro"
        ShareName = "Financeiro"
        NTFSRights = "Modify"
        ShareRights = "Change"
    },
    @{
        Path = "D:\ARQUIVOS\Departamentos\TI"
        GroupName = "GRP_TI"
        ShareName = "TI"
        NTFSRights = "Modify"
        ShareRights = "Change"
    }
)

# Unidade organizacional para grupos
$ouPath = "OU=Groups,DC=empresa,DC=local"

# 1. Criar grupos de segurança
Write-Log "Criando grupos de segurança no Active Directory..."
foreach ($config in $folderConfig) {
    $groupName = $config.GroupName
    try {
        if (-not (Get-ADGroup -Filter { Name -eq $groupName } -ErrorAction SilentlyContinue)) {
            New-ADGroup -Name $groupName -SamAccountName $groupName -GroupScope Global -GroupCategory Security -Path $ouPath -Description "Grupo para acesso à pasta $($config.Path)" -ErrorAction Stop
            Write-Log "Grupo ${groupName} criado com sucesso."
        } else {
            Write-Log "Grupo ${groupName} já existe."
        }
    } catch {
        Write-Log "Erro ao criar grupo ${groupName}: $_"
    }
}

# 2. Configurar permissões NTFS e compartilhamentos
foreach ($config in $folderConfig) {
    $folderPath = $config.Path
    $groupName = $config.GroupName
    $shareName = $config.ShareName
    $ntfsRights = $config.NTFSRights
    $shareRights = $config.ShareRights

    # Verificar se a pasta existe
    if (-not (Test-Path $folderPath)) {
        Write-Log "Pasta ${folderPath} não encontrada. Pulando configuração."
        continue
    }

    # 2.1. Configurar permissões NTFS
    Write-Log "Configurando permissões NTFS para ${folderPath}..."
    try {
        # Desativar herança e remover permissões existentes
        $acl = Get-Acl -Path $folderPath
        $acl.SetAccessRuleProtection($true, $false)
        $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }

        # Adicionar permissão para o grupo
        $groupSid = (Get-ADGroup -Identity $groupName).SID
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

    # 2.2. Configurar compartilhamento
    Write-Log "Configurando compartilhamento para ${folderPath}..."
    try {
        # Remover compartilhamento existente, se houver
        if (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue) {
            Remove-SmbShare -Name $shareName -Force -ErrorAction Stop
            Write-Log "Compartilhamento ${shareName} existente removido."
        }

        # Criar novo compartilhamento
        New-SmbShare -Name $shareName -Path $folderPath -Description "Compartilhamento para ${shareName}" -FullAccess "BUILTIN\Administrators" -ChangeAccess $groupName -ErrorAction Stop
        Write-Log "Compartilhamento ${shareName} criado com sucesso."
    } catch {
        Write-Log "Erro ao configurar compartilhamento ${shareName}: $_"
    }
}

# 3. Mensagem de conclusão
Write-Log "Configuração de grupos e permissões concluída. Log salvo em ${logPath}."