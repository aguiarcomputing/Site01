# Verificar status do AD DS
Get-ADDomain | Select-Object Name, DomainMode
Get-ADForest | Select-Object Name, ForestMode

# Verificar registros DNS
nslookup $DomainName

# Testar integridade do DC
dcdiag /v