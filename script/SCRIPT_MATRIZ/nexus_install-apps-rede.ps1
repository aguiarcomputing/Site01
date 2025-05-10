## Install whats app bussines pela rede
$whatsappUrl = "\\172.17.0.252\dados_rede$\sUPORTE\APPs\WhatsApp Installer.exe"
$localPath = "$env:TEMP\WhatsAppSetup.exe"
try {
    if (Test-Path $whatsappUrl) {
        Copy-Item -Path $whatsappUrl -Destination $localPath -Force
        Start-Process -FilePath $localPath -Wait
        Write-Host "WhatsApp Desktop instalado. Use sua conta Business para conectar." -ForegroundColor Green
    } else {
        Write-Host "Arquivo de instalação não encontrado em: $whatsappUrl" -ForegroundColor Red
    }
} catch {
    Write-Host "Erro durante a instalação: $_" -ForegroundColor Red
}

## Install Telegram Desktop pela rede
$networkInstaller = "\\172.17.0.252\dados_rede$\sUPORTE\APPs\tsetup-x64.5.13.1.exe"
$localPath = "$env:TEMP\TelegramSetup.exe"
Copy-Item -Path $networkInstaller -Destination $localPath -Force
Start-Process -FilePath $localPath -Wait
Write-Host "Telegram Desktop instalado. Faça login com seu número de telefone para começar a usar." -ForegroundColor Green


## Install ibridg pela rede
#$rede = "\\172.17.0.252\dados_rede$\sUPORTE\APPs\iBRIDGE-Softphone-3.20.7.exe"
#$destino = "$env:TEMP\iBRIDGE-Softphone-3.20.7.exe"
#Copy-Item -Path $rede -Destination $destino -Force
#Start-Process -FilePath $destino -ArgumentList "/S" -Wait
#Remove-Item $destino -Force
#Write-Host "iBRIDGE Softphone instalado com sucesso." -ForegroundColor Green

#Verifica se o IBridge esta instalado se não, instala pela rede
$nomePrograma = "iBRIDGE Softphone"
$instalado = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* ,
                         HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
             Where-Object { $_.DisplayName -like "*$nomePrograma*" }
if ($instalado) {
    Write-Host "$nomePrograma já está instalado. Nenhuma ação necessária." -ForegroundColor Yellow
} else {
    $rede = "\\172.17.0.252\dados_rede$\sUPORTE\APPs\iBRIDGE-Softphone-3.20.7.exe"
    $destino = "$env:TEMP\iBRIDGE-Softphone-3.20.7.exe"
    Copy-Item -Path $rede -Destination $destino -Force
    Start-Process -FilePath $destino -ArgumentList "/S" -Wait
    Remove-Item $destino -Force

    Write-Host "iBRIDGE Softphone instalado com sucesso." -ForegroundColor Green
}


# Caminho do instalador na rede
$rede = "\\172.17.0.252\dados_rede$\sUPORTE\APPs\ChromeSetup.exe"
$destino = "$env:TEMP\ChromeSetup.exe"
Copy-Item -Path $rede -Destination $destino -Force
Start-Process -FilePath $destino -ArgumentList "/silent", "/install" -Wait
Remove-Item $destino -Force
Write-Host "Google Chrome instalado com sucesso." -ForegroundColor Green
