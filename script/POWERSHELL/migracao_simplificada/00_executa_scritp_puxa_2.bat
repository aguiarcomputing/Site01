@echo off
powershell -Command "Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force"
echo Política de execução do PowerShell definida como Unrestricted.

REM Executa o script PowerShell como administrador
powershell -Command "Start-Process powershell -ArgumentList '-File \"C:\Nova pasta\2_script_useradmin_copia_dominio.ps1"' -Verb RunAs"

pause