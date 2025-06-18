@echo off
setlocal EnableDelayedExpansion

:: Configura cores para exibição (verde para cabeçalho, ciano para informações da empresa, amarelo para resultados)
color 0a
cls

:: Exibe informações da empresa de forma profissional
echo.
echo [1;36m==================================================[0m
echo [1;36m         AGUIAR INFORMATICA - IT Solutions         [0m
echo [1;36m==================================================[0m
echo.
echo [1;33mTelefone: (48) 9 9189-0567[0m
echo [1;33mSite: https://www.aguiarinformatica.com.br/[0m
echo [1;33mE-mail: suporte@aguiarinformatica.com.br[0m
echo.
echo [1;36m--------------------------------------------------[0m
echo.

:: Executa o comando WMIC e salva a saída em um arquivo temporário
echo [1;32mCOLETANDO INFORMACOES DA MEMORIA...[0m
wmic memorychip get Capacity, Manufacturer, PartNumber, Speed > "%temp%\memory_info.txt"

:: Exibe o conteúdo do arquivo temporário com formatação
echo.
echo [1;33mINFORMACOES da MEMORIA:[0m
echo.
type "%temp%\memory_info.txt"
echo.

:: Pergunta ao usuário se deseja copiar o resultado para a área de transferência
set /p copy_choice=[1;32mDESEJA COPIAR AS INFORMACOES PARA A AREA DE TRANSFERENCIA? (S/N): [0m
if /i "!copy_choice!"=="S" (
    clip < "%temp%\memory_info.txt"
    echo.
    echo [1;32mINFORMACOES COPIADAS PARA A AREA DE TRANSFERENCIA![0m
)

:: Remove o arquivo temporário
del "%temp%\memory_info.txt"

echo.
echo [1;36m--------------------------------------------------[0m
echo [1;36mOBRIGADO POR UTILIZAR SERVICOS DA AGUIAR INFORMATICA![0m
echo.

pause
endlocal