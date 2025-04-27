@echo off
REM Arquivo: RunRenameAdmin.bat
REM Descrição: Chama o script PowerShell para renomear o Administrador

REM Define o caminho do script PowerShell (ajuste conforme o local onde salvar)
set "PSScriptPath=%~dp0RenameAdmin.ps1"

REM Verifica se o script PowerShell existe
if not exist "%PSScriptPath%" (
    echo Erro: O script PowerShell "%PSScriptPath%" nao foi encontrado!
    pause
    exit /b 1
)

REM Executa o PowerShell com privilégios elevados
powershell -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%PSScriptPath%""' -Verb RunAs"

REM Verifica se houve erro na execução
if %ERRORLEVEL% neq 0 (
    echo Erro ao executar o script PowerShell!
    pause
    exit /b 1
)

echo Script executado. Verifique o resultado no PowerShell.
pause