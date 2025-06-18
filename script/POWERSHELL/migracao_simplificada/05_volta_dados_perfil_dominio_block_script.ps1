# Obtém o nome do usuário logado corretamente (Ignora usuários do sistema)
$usuarioLogado = (Get-WMIObject Win32_ComputerSystem | Select-Object -ExpandProperty UserName) -replace '.*\\'

# Obtém o caminho do perfil do usuário logado corretamente
$perfilUsuario = [System.IO.Path]::Combine("C:\Users", $usuarioLogado)

# Exibe o perfil encontrado para depuração
Write-Host "O perfil do usuário logado foi identificado como: $perfilUsuario" -ForegroundColor Cyan

# Diretório de origem (backup)
$origem = "C:\Migra"

# Diretórios de destino dentro do perfil correto
$destinoDocumentos = "$perfilUsuario\Documents"
$destinoDownloads = "$perfilUsuario\Downloads"
$destinoDesktop = "$perfilUsuario\Desktop"
$destinoPictures = "$perfilUsuario\Pictures"
$destinoAtalhos = "$perfilUsuario\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"

# Arquivo de log
$logFile = "C:\Nova Pasta\backup_log.txt"

# Define a codificação UTF-8 sem BOM para evitar caracteres ilegíveis
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false

# Escreve cabeçalho no log
$header = "===== Início da Restauração para ${usuarioLogado}: $(Get-Date) =====`n"
[System.IO.File]::WriteAllText($logFile, $header, $Utf8NoBomEncoding)

# Função para copiar arquivos usando Robocopy
function Restaurar-Arquivos {
    param (
        [string]$origem,
        [string]$destino
    )
    Write-Host "Copiando de '$origem' para '$destino'..." -ForegroundColor Yellow

    if (Test-Path $origem) {
        $logTemp = "$logFile.tmp"
        
        robocopy $origem $destino /E /COPY:DAT /A-:SH /XJ /IS /IT /ZB /NP /TEE /LOG:$logTemp
        
        # Converte o log temporário para UTF-8 sem BOM e adiciona ao log final
        $conteudo = Get-Content $logTemp -Raw
        [System.IO.File]::AppendAllText($logFile, $conteudo, $Utf8NoBomEncoding)
        
        Remove-Item $logTemp -Force
    } else {
        $aviso = "Aviso: O diretório ${origem} não existe. $(Get-Date)`n"
        [System.IO.File]::AppendAllText($logFile, $aviso, $Utf8NoBomEncoding)
    }
}

# Confirma que o perfil foi identificado corretamente
if (Test-Path $perfilUsuario) {
    try {
        # Executa a restauração para cada pasta do usuário logado
        Restaurar-Arquivos "$origem\Documentos" $destinoDocumentos
        Restaurar-Arquivos "$origem\Downloads" $destinoDownloads
        Restaurar-Arquivos "$origem\Desktop" $destinoDesktop
        Restaurar-Arquivos "$origem\Pictures" $destinoPictures
        Restaurar-Arquivos "$origem\Atalhos_menu" $destinoAtalhos

        # Finaliza log
        $footer = "===== Restauração concluída para ${usuarioLogado}: $(Get-Date) =====`n"
        [System.IO.File]::AppendAllText($logFile, $footer, $Utf8NoBomEncoding)

        Write-Host "Restauração concluída para ${usuarioLogado}! Verifique o log em $logFile" -ForegroundColor Green

        # Bloqueia novamente a execução de scripts no PowerShell
        Set-ExecutionPolicy Restricted -Scope LocalMachine -Force
        Write-Host "Política de execução do PowerShell redefinida para Restricted." -ForegroundColor Yellow

        # Apaga as pastas C:\Migra e C:\Nova Pasta
        Remove-Item -Path "C:\Migra" -Recurse -Force
        Remove-Item -Path "C:\Nova Pasta" -Recurse -Force
        Write-Host "Pastas C:\Migra e C:\Nova Pasta foram apagadas." -ForegroundColor Green
    } catch {
        Write-Host "Erro durante a restauração: $_" -ForegroundColor Red
        # Abre o arquivo de log para análise
        Invoke-Item $logFile
    }
} else {
    Write-Host "Erro: O perfil do usuário ${usuarioLogado} não foi encontrado!" -ForegroundColor Red
    # Abre o arquivo de log para análise
    Invoke-Item $logFile
}