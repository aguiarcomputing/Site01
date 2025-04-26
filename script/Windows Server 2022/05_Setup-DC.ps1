# Parâmetros do domínio
$DomainName = "empresa.local"
$NetBIOSName = "EMPRESA"
$SafeModeAdminPassword = ConvertTo-SecureString "bz07fx$#oela14" -AsPlainText -Force
$ForestMode = "WinThreshold"  # Nível funcional (WinThreshold para 2016/2019/2022)
$DomainMode = "WinThreshold"

# Instalar função AD DS e ferramentas
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -IncludeAllSubFeature

# Instalar função DNS (recomendado para DCs)
Install-WindowsFeature -Name DNS -IncludeManagementTools

# Promover a controlador de domínio e criar nova floresta
Install-ADDSForest `
    -DomainName $DomainName `
    -DomainNetBIOSName $NetBIOSName `
    -ForestMode $ForestMode `
    -DomainMode $DomainMode `
    -SafeModeAdministratorPassword $SafeModeAdminPassword `
    -InstallDNS:$true `
    -NoRebootOnCompletion:$false `
    -Force:$true

# O servidor reiniciará automaticamente após a promoção