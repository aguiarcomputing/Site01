@echo off
title Menu de Controle do Firewall do Windows
color 0a

:: Verifica se o script está sendo executado com privilégios administrativos
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Este script precisa ser executado como Administrador.
    echo Clique com o botao direito no arquivo e selecione "Executar como administrador".
    pause
    exit /b
)

:menu
cls
echo ==============================
echo    Menu de Controle do Firewall
echo ==============================
echo 1. Habilitar Firewall
echo 2. Desabilitar Firewall
echo 3. Verificar Status do Firewall
echo 4. Sair
echo ==============================
set /p opcao="Escolha uma opcao (1-4): "

if "%opcao%"=="1" goto habilitar
if "%opcao%"=="2" goto desabilitar
if "%opcao%"=="3" goto verificar
if "%opcao%"=="4" goto sair
echo Opcao invalida! Pressione qualquer tecla para tentar novamente.
pause >nul
goto menu

:habilitar
powershell -Command "Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True"
echo.
echo Firewall foi HABILITADO para todos os perfis.
pause
goto menu

:desabilitar
powershell -Command "Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled False"
echo.
echo Firewall foi DESABILITADO para todos os perfis.
pause
goto menu

:verificar
powershell -Command "Get-NetFirewallProfile | Select-Object Name, Enabled | Format-Table -AutoSize"
echo.
echo Status do Firewall exibido acima.
pause
goto menu

:sair
echo Saindo do menu...
pause
exit