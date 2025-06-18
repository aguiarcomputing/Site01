# Renomear Administrador local e alterar senha
$NovoNome = "itconnectadm"
$NovaSenha = "96PO08as!@)(%" | ConvertTo-SecureString -AsPlainText -Force

# Obter usuario Administrador local
$AdminUser = Get-WmiObject Win32_UserAccount -Filter "Name='Administrador' AND LocalAccount=True"

if ($AdminUser) {
    Write-Host "Renomeando Administrador para $NovoNome..."
    Rename-LocalUser -Name "Administrador" -NewName $NovoNome

    Write-Host "Alterando senha do usuario $NovoNome..."
    Set-LocalUser -Name $NovoNome -Password $NovaSenha

    Write-Host "Ativando o usuario $NovoNome..."
    Enable-LocalUser -Name $NovoNome

    # Criar Log
    $Log = "Usuario renomeado para $NovoNome e senha alterada em $(Get-Date)"
    $Log | Out-File -Append C:\Renomear_Admin.log

    Write-Host "Operacao conclui­da com sucesso!"
} else {
    Write-Host "Usuario 'Administrador' nao encontrado."
    "Falha ao renomear usuario em $(Get-Date)" | Out-File -Append C:\Renomear_Admin.log
}

# Obtém o nome do usuário ativo (evita capturar 'Administrador')
$usuarioLogado = (Get-WMIObject Win32_ComputerSystem | Select-Object -ExpandProperty UserName) -replace '.*\\'

# Caminho correto do perfil do usuário
$perfilUsuario = "C:\Users\$usuarioLogado"

Write-Host "Perfil do usuário logado: $perfilUsuario" -ForegroundColor Cyan

# Diretório de destino
$destino = "C:\Migra"

# Lista de pastas a serem copiadas
$pastas = @("Documents", "Downloads", "Desktop", "Pictures")

# Criar diretorios no destino
foreach ($pasta in $pastas) {
    $caminho = Join-Path -Path $destino -ChildPath $pasta
    if (!(Test-Path $caminho)) {
        New-Item -ItemType Directory -Path $caminho -Force | Out-Null
    }
}

# Caminhos de origem
$origemDocumentos = "$perfilUsuario\Documents"
$origemDownloads = "$perfilUsuario\Downloads"
$origemDesktop = "$perfilUsuario\Desktop"
$origemPictures = "$perfilUsuario\Pictures"
$origemAtalhos = "$perfilUsuario\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"

# Função para copiar arquivos usando robocopy
function Copiar-Arquivos($origem, $destino) {
    if (Test-Path $origem) {
        Write-Host "Copiando de '$origem' para '$destino'..." -ForegroundColor Yellow
        robocopy $origem $destino /E /COPY:DAT /A-:SH /XJ /IS /IT /ZB /NP /TEE | Out-Null
    } else {
        Write-Host "Aviso: O diretório $origem não existe." -ForegroundColor Red
    }
}

# Copiar os arquivos das pastas do usuario logado
Copiar-Arquivos $origemDocumentos "$destino\Documents"
Copiar-Arquivos $origemDownloads "$destino\Downloads"
Copiar-Arquivos $origemDesktop "$destino\Desktop"
Copiar-Arquivos $origemPictures "$destino\Pictures"
Copiar-Arquivos $origemAtalhos "$destino\Atalhos_menu"

Write-Host "Copia concluida!" -ForegroundColor Green


#Script para migrar maquinas para dominio


# Definir variaveis
$DomainName = "itconnect.local"  # Nome do domi­nio
$AdminUser = "itconnectadm"       # Usuario com permissao para adicionar ao domi­nio
$AdminPassword = "96PO08as!@)(%"      # Senha do usuario administrador do domi­nio
$LocalUser = $env:UserName         # Obtem o nome do usuario local logado

# Criar credencial para ingressar no dominio
$SecurePassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential("$DomainName\$AdminUser", $SecurePassword)

# Verificar se a maquina ja estao no domi­nio
$ComputerInfo = Get-WmiObject Win32_ComputerSystem
if ($ComputerInfo.PartOfDomain -eq $true) {
    Write-Host "Este computador ja esta no domi­nio: $DomainName" -ForegroundColor Green
    exit
}

# Adicionar a maquina ao dominio
Write-Host "Adicionando a maquina ao dominio $DomainName..." -ForegroundColor Yellow
Add-Computer -DomainName $DomainName -Credential $Credential -Restart -Force
