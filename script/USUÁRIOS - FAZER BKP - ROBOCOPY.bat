@echo off
:: Verifica se o script está sendo executado com privilégios de administrador
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Este script precisa ser executado como Administrador.
    pause
    exit /b
)

:: Define o caminho do HD externo (altere conforme necessário)
set "Destino=D:\BACKUP COMERCIAL\vinicius prestes"

:: Define as pastas de origem
set "PastaDesktop=C:\Users\vinicius prestes\Desktop"
set "PastaContacts=C:\Users\vinicius prestes\Contacts"
set "PastaDocuments=C:\Users\vinicius prestes\Documents"
set "PastaDownloads=C:\Users\vinicius prestes\Downloads"
set "PastaFavorites=C:\Users\vinicius prestes\Favorites"
set "PastaPictures=C:\Users\vinicius prestes\Pictures"

:: Cria o diretório de destino no HD externo, se não existir
if not exist "%Destino%" (
    mkdir "%Destino%"
)

:: Função para copiar e validar cada pasta
:CopyAndValidate
echo Iniciando a copia das pastas para %Destino%...

:: Copiar Desktop
echo Copiando Desktop...
robocopy "%PastaDesktop%" "%Destino%\Desktop" /E /COPYALL /R:3 /W:5 /LOG:"%Destino%\Desktop_CopyLog.txt"
if %errorlevel% GEQ 8 (
    echo Falha ao copiar Desktop. Verifique o log em %Destino%\Desktop_CopyLog.txt
) else (
    echo Desktop copiado com sucesso.
)

:: Copiar Contacts
echo Copiando Contacts...
robocopy "%PastaContacts%" "%Destino%\Contacts" /E /COPYALL /R:3 /W:5 /LOG:"%Destino%\Contacts_CopyLog.txt"
if %errorlevel% GEQ 8 (
    echo Falha ao copiar Contacts. Verifique o log em %Destino%\Contacts_CopyLog.txt
) else (
    echo Contacts copiado com sucesso.
)

:: Copiar Documents
echo Copiando Documents...
robocopy "%PastaDocuments%" "%Destino%\Documents" /E /COPYALL /R:3 /W:5 /LOG:"%Destino%\Documents_CopyLog.txt"
if %errorlevel% GEQ 8 (
    echo Falha ao copiar Documents. Verifique o log em %Destino%\Documents_CopyLog.txt
) else (
    echo Documents copiado com sucesso.
)

:: Copiar Downloads
echo Copiando Downloads...
robocopy "%PastaDownloads%" "%Destino%\Downloads" /E /COPYALL /R:3 /W:5 /LOG:"%Destino%\Downloads_CopyLog.txt"
if %errorlevel% GEQ 8 (
    echo Falha ao copiar Downloads. Verifique o log em %Destino%\Downloads_CopyLog.txt
) else (
    echo Downloads copiado com sucesso.
)

:: Copiar Favorites
echo Copiando Favorites...
robocopy "%PastaFavorites%" "%Destino%\Favorites" /E /COPYALL /R:3 /W:5 /LOG:"%Destino%\Favorites_CopyLog.txt"
if %errorlevel% GEQ 8 (
    echo Falha ao copiar Favorites. Verifique o log em %Destino%\Favorites_CopyLog.txt
) else (
    echo Favorites copiado com sucesso.
)

:: Copiar Pictures
echo Copiando Pictures...
robocopy "%PastaPictures%" "%Destino%\Pictures" /E /COPYALL /R:3 /W:5 /LOG:"%Destino%\Pictures_CopyLog.txt"
if %errorlevel% GEQ 8 (
    echo Falha ao copiar Pictures. Verifique o log em %Destino%\Pictures_CopyLog.txt
) else (
    echo Pictures copiado com sucesso.
)

:: Finalização
echo Processo de backup concluido. Verifique os logs para detalhes.
pause