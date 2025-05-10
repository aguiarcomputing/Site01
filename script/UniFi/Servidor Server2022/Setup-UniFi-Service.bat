@echo off
setlocal

:: Verifica se o script está sendo executado como administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Este script precisa ser executado como administrador.
    echo Clique com o botao direito no arquivo e selecione "Executar como administrador".
    pause
    exit /b 1
)

:: Define o diretório de instalação do UniFi
set UNIFI_DIR=%UserProfile%\Ubiquiti UniFi

:: Verifica se o diretório do UniFi existe
if not exist "%UNIFI_DIR%" (
    echo O diretorio %UNIFI_DIR% nao foi encontrado.
    echo Certifique-se de que o UniFi Controller esta instalado no local padrao.
    pause
    exit /b 1
)

:: Navega até o diretório do UniFi
cd /d "%UNIFI_DIR%"

:: Instala o UniFi Controller como serviço
echo Instalando o UniFi Controller como servico...
java -jar lib\ace.jar installsvc
if %errorlevel% equ 0 (
    echo Servico instalado com sucesso.
) else (
    echo Erro ao instalar o servico. Verifique se o Java esta instalado e o UniFi Controller esta configurado corretamente.
    pause
    exit /b 1
)

:: Inicia o serviço do UniFi Controller
echo Iniciando o servico do UniFi Controller...
java -jar lib\ace.jar startsvc
if %errorlevel% equ 0 (
    echo Servico iniciado com sucesso.
) else (
    echo Erro ao iniciar o servico. Verifique o status do servico no Gerenciador de Servicos do Windows.
    pause
    exit /b 1
)

echo Configuracao concluida. O UniFi Controller agora rodara como um servico e iniciara automaticamente com o Windows.
pause
endlocal