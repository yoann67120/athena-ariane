Write-Host '🚀 Démarrage du système vocal Athena...' -ForegroundColor Cyan
Set-Location 'C:\Ariane-Agent\Modules\Athena.Voice'
Start-Process powershell -WindowStyle Hidden -ArgumentList 'python Athena.VoiceLink.py'
Start-Sleep -Seconds 3
python Athena.TTS.py
