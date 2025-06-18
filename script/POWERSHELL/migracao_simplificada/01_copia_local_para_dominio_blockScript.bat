@echo off

REM Executa o script PowerShell como administrador
powershell -Command "Start-Process powershell -ArgumentList '-File \"C:\Nova pasta\04_volta_dados_perfil_dominio_block_script"' -Verb RunAs"

pause