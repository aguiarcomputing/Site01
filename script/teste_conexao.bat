@echo off
setlocal EnableDelayedExpansion

echo Iniciando o teste de conexao por 10 minutos...
echo Iniciando o teste de conexao... > logparaoprovedor.txt
echo -------------------------------- >> logparaoprovedor.txt

REM Registra data e hora
echo Data do teste: >> logparaoprovedor.txt
date /t >> logparaoprovedor.txt
echo Horario de inicio: >> logparaoprovedor.txt
time /t >> logparaoprovedor.txt
echo. >> logparaoprovedor.txt

REM Informações do teste
echo Realizando teste de latencia para 8.8.8.8 (Google DNS) por 10 minutos... >> logparaoprovedor.txt
echo O teste sera concluido automaticamente apos 600 segundos >> logparaoprovedor.txt
echo -------------------------------- >> logparaoprovedor.txt

REM Variáveis para análise
set "count=0"
set "total_ms=0"
set "losses=0"

REM Arquivo temporário para capturar o ping
set "tempfile=temp_ping.txt"
if exist %tempfile% del %tempfile%

REM Executa o ping por 10 minutos (600 segundos)
echo Iniciando ping - pressione Ctrl+C apenas se quiser interromper antes
ping 8.8.8.8 -n 600 > %tempfile%

REM Analisa os resultados
echo. >> logparaoprovedor.txt
echo Analise dos resultados: >> logparaoprovedor.txt
echo -------------------------------- >> logparaoprovedor.txt

for /f "tokens=*" %%a in (%tempfile%) do (
    echo %%a >> logparaoprovedor.txt
    REM Extrai tempo de resposta
    for /f "tokens=9 delims= " %%b in ("%%a") do (
        set "time_str=%%b"
        if "!time_str:~0,5!"=="tempo" (
            set /a count+=1
            for /f "tokens=2 delims==" %%c in ("!time_str!") do (
                set "ms=%%c"
                set "ms=!ms:ms=!"
                if !ms! lss 1000 (
                    set /a total_ms+=!ms!
                )
            )
        )
    )
    REM Conta perdas
    echo %%a | find "Esgotado" >nul && set /a losses+=1
    echo %%a | find "unreachable" >nul && set /a losses+=1
)

REM Calcula latência média e percentual de perda
if %count% gtr 0 (
    set /a "avg_ms=%total_ms% / %count%"
    set /a "loss_percent=(%losses% * 100) / (%count% + %losses%)"
) else (
    set "avg_ms=0"
    set "loss_percent=100"
)

REM Registra estatísticas
echo. >> logparaoprovedor.txt
echo Estatisticas finais: >> logparaoprovedor.txt
echo Pacotes enviados: %count%+%losses% >> logparaoprovedor.txt
echo Pacotes perdidos: %losses% (%loss_percent%%%) >> logparaoprovedor.txt
echo Latencia media: %avg_ms%ms >> logparaoprovedor.txt

REM Avaliação da conexão
echo. >> logparaoprovedor.txt
echo Avaliacao da conexao: >> logparaoprovedor.txt
if %loss_percent% gtr 5 (
    echo ATENCAO: Alta perda de pacotes detectada (%loss_percent%%%) - Conexao instavel >> logparaoprovedor.txt
) else (
    echo Perda de pacotes aceitavel (%loss_percent%%%) >> logparaoprovedor.txt
)

if %avg_ms% gtr 100 (
    echo ATENCAO: Latencia elevada (%avg_ms%ms) - Conexao lenta >> logparaoprovedor.txt
) else if %avg_ms% gtr 50 (
    echo Latencia moderada (%avg_ms%ms) - Pode afetar jogos/jogatinas >> logparaoprovedor.txt
) else (
    echo Latencia boa (%avg_ms%ms) - Conexao adequada >> logparaoprovedor.txt
)

REM Horario de término
echo. >> logparaoprovedor.txt
echo Horario de termino: >> logparaoprovedor.txt
time /t >> logparaoprovedor.txt

REM Limpeza
if exist %tempfile% del %tempfile%

REM Mensagem final com local do arquivo e tempo de fechamento
echo. >> logparaoprovedor.txt
echo -------------------------------- >> logparaoprovedor.txt
echo Teste concluido. Os resultados foram salvos em: %CD%\logparaoprovedor.txt >> logparaoprovedor.txt
echo Este programa sera fechado automaticamente em 10 segundos. >> logparaoprovedor.txt

echo Teste concluido.
echo Os resultados foram salvos em: %CD%\logparaoprovedor.txt
echo Este programa sera fechado automaticamente em 10 segundos.
timeout /t 10 /nobreak >nul

exit