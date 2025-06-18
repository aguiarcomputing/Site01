@echo off
:: Verifica se está sendo executado como Administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Solicitando permissões de Administrador...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~fnx0' -Verb RunAs"
    exit
)

:: Executa o script PowerShell como Administrador
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0ITCONNECTADM.ps1"
pause