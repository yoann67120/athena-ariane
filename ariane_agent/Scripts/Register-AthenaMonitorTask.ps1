# Register-AthenaMonitorTask.ps1
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -File C:/Ariane-Agent/Scripts/Start-Monitor.ps1"
$trigger = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -TaskName "AthenaV4_Monitor" -Action $action -Trigger $trigger -Description "Surveillance & Auto-Restart Athena V4" -Force
Write-Host "✅ Tâche planifiée 'AthenaV4_Monitor' enregistrée."