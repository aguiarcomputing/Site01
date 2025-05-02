@echo off
setlocal EnableDelayedExpansion

:MainLoop
cls
echo ==============================================
echo         MENU DE CONFIGURACAO NEXUS
echo ==============================================
echo 1. Mapear servidores (ADFS01/ADFS02)
echo 2. Verificar permissao de Administrador
echo 3. Habilitar execucao de scripts PowerShell
echo 4. Criar/modificar usuarios ITC e NEXUS
echo 5. Instalar programas padroes
echo 6. Adicionar maquina ao dominio
echo 7. Sair
echo ==============================================
set /p choice="Digite a opcao (1-7): "

if "!choice!"=="1" goto MapServers
if "!choice!"=="2" goto CheckAdmin
if "!choice!"=="3" goto EnableScripts
if "!choice!"=="4" goto CreateUsers
if "!choice!"=="5" goto InstallApps
if "!choice!"=="6" goto JoinDomain
if "!choice!"=="7" goto End
echo Opcao invalida! Pressione qualquer tecla para continuar.
pause >nul
goto MainLoop

:MapServers
cls
echo === Mapeando servidores ADFS01/ADFS02 ===
echo Conectando a \\nxs-srv-adfs02.nexus.local...
net use \\nxs-srv-adfs02.nexus.local /USER:nexus Nexus@1
if !errorlevel! neq 0 (
    echo Erro ao conectar a \\nxs-srv-adfs02.nexus.local!
) else (
    echo Conectado com sucesso!
)
pause

echo Conectando a \\172.17.0.251...
net use \\172.17.0.251 /USER:nexus Nexus@1
if !errorlevel! neq 0 (
    echo Erro ao conectar a \\172.17.0.251!
) else (
    echo Conectado com sucesso!
)
pause

echo Conectando a \\nxs-srv-adfs01.nexus.local...
net use \\nxs-srv-adfs01.nexus.local /USER:nexus Nexus@1
if !errorlevel! neq 0 (
    echo Erro ao conectar a \\nxs-srv-adfs01.nexus.local!
) else (
    echo Conectado com sucesso!
)
pause

echo Conectando a \\172.17.0.252...
net use \\172.17.0.252 /USER:nexus Nexus@1
if !errorlevel! neq 0 (
    echo Erro ao conectar a \\172.17.0.252!
) else (
    echo Conectado com sucesso!
)
pause

echo Conectando a \\172.17.0.252\dados_rede$...
net use \\172.17.0.252\dados_rede$ /USER:nexus Nexus@1
if !errorlevel! neq 0 (
    echo Erro ao conectar a \\172.17.0.252\dados_rede$!
) else (
    echo Conectado com sucesso!
)
pause

echo Mapeamento de servidores concluido!
set /p next="Pressione Enter para continuar ou 'S' para sair: "
if /i "!next!"=="S" goto End
goto MainLoop

:CheckAdmin
cls
echo === Verificando permissao de Administrador ===
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo Solicitando permissoes de Administrador...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~fnx0' -Verb RunAs"
    exit
) else (
    echo Permissoes de Administrador confirmadas!
)
pause
echo Verificacao concluida!
set /p next="Pressione Enter para continuar ou 'S' para sair: "
if /i "!next!"=="S" goto End
goto MainLoop

:EnableScripts
cls
echo === Habilitando execucao de scripts PowerShell ===
echo Permitindo scripts locais sem assinatura digital...
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0habilitar_exec_scripts_user.ps1"
if !errorlevel! neq 0 (
    echo Erro ao executar o script habilitar_exec_scripts_user.ps1!
) else (
    echo Script executado com sucesso!
)
pause
echo Configuracao concluida!
set /p next="Pressione Enter para continuar ou 'S' para sair: "
if /i "!next!"=="S" goto End
goto MainLoop

:CreateUsers
cls
echo === Criando/modificando usuarios ITC e NEXUS ===
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0nexusadm_itconnectadm.ps1"
if !errorlevel! neq 0 (
    echo Erro ao executar o script nexusadm_itconnectadm.ps1!
) else (
    echo Usuarios criados/modificados com sucesso!
)
pause
echo Configuracao concluida!
set /p next="Pressione Enter para continuar ou 'S' para sair: "
if /i "!next!"=="S" goto End
goto MainLoop

:InstallApps
cls
echo === Instalando programas padroes ===
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0nexus_install-apps-rede.ps1"
if !errorlevel! neq 0 (
    echo Erro ao executar o script nexus_install-apps-rede.ps1!
) else (
    echo Programas instalados com sucesso!
)
pause
echo Instalacao concluida!
set /p next="Pressione Enter para continuar ou 'S' para sair: "
if /i "!next!"=="S" goto End
goto MainLoop

:JoinDomain
cls
echo === Adicionando maquina ao dominio ===
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0AddHost-Dominio.ps1"
if !errorlevel! neq 0 (
    echo Erro ao executar o script AddHost-Dominio.ps1!
) else (
    echo Maquina adicionada ao dominio com sucesso!
)
pause
echo Configuracao concluida!
set /p next="Pressione Enter para continuar ou 'S' para sair: "
if /i "!next!"=="S" goto End
goto MainLoop

:End
cls
echo === Configuracao finalizada! ===
echo Cabooooooooooo!
pause
exit