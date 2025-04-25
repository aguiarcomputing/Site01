## Install whats app bussines
$whatsappUrl = "https://web.whatsapp.com/desktop/windows/release/x64/WhatsAppSetup.exe"
$localPath = "$env:TEMP\WhatsAppSetup.exe"
Invoke-WebRequest -Uri $whatsappUrl -OutFile $localPath
Start-Process -FilePath $localPath -Wait
Write-Host "WhatsApp Desktop instalado. Use sua conta Business para conectar." -ForegroundColor Green

## Install Telegram Desktop
$telegramUrl = "https://telegram.org/dl/desktop/win64"
$localPath = "$env:TEMP\TelegramSetup.exe"
Invoke-WebRequest -Uri $telegramUrl -OutFile $localPath
Start-Process -FilePath $localPath -Wait
Write-Host "Telegram Desktop instalado. Faça login com seu número de telefone para começar a usar." -ForegroundColor Green


## Install ibridg
$destino = "$env:TEMP\iBRIDGE-Softphone-3.20.7.exe"
$url = "https://www.ibridge.com.br/arquivos-download/iBRIDGE-Softphone-3.20.7.exe"  # Exemplo fictício
Invoke-WebRequest -Uri $url -OutFile $destino
Start-Process -FilePath $destino -ArgumentList "/S" -Wait
Remove-Item $destino







