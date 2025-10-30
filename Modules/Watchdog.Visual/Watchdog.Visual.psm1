# ====================================================================
# ðŸ§  Ariane V4 / Athena â€“ Watchdog.Visual.psm1 (v1.0.2-stable)
# Surveillance cockpit visuel + relance automatique + annonces vocales
# Phase 12 â€” Watchdog + Auto-Repair + Visual Sync
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'
$PSModuleAutoLoadingPreference = 'None'

$script:ModuleDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:RootDir    = Split-Path -Parent $script:ModuleDir
$script:LogsDir    = Join-Path $script:RootDir 'Logs'
$script:DataDir    = Join-Path $script:RootDir 'Data'

if (!(Test-Path $script:LogsDir)) { New-Item -ItemType Directory -Path $script:LogsDir -Force | Out-Null }
$script:LogFile = Join-Path $script:LogsDir 'WatchdogVisual.log'

$script:DefaultIntervalMinutes = 5
$script:DashboardPath = Join-Path $script:LogsDir 'dashboard.json'
$script:StartCockpitScript = Join-Path $script:RootDir 'Start-Cockpit.ps1'
$script:DashboardMaxAge = [TimeSpan]::FromHours(24)

$script:WatchdogCts = $null
$script:LastStatus = [ordered]@{
  Timestamp = (Get-Date)
  CockpitOk = $false
  VoiceOk   = $false
  SoundOk   = $false
  DashOk    = $false
  Action    = 'Init'
  Details   = ''
}

function Write-WatchdogLog {
  param([string]$Message,[ValidateSet('INFO','WARN','ERROR')][string]$Level='INFO')
  $ts=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
  Add-Content -Path $script:LogFile -Value "[$ts] [$Level] $Message"
}

function Test-CockpitWindow {
  try {
    $procs = Get-Process -Name 'powershell' -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 }
    if (-not $procs) { return $false }
    foreach ($p in $procs) {
      if ($p.MainWindowTitle -match 'Cockpit|Athena|K2000') { return $true }
    }
    return $false
  } catch { return $false }
}

function Test-VoiceEngine {
  try {
    Add-Type -AssemblyName System.Speech -ErrorAction Stop
    $s = New-Object System.Speech.Synthesis.SpeechSynthesizer
    return ($null -ne $s)
  } catch { return $false }
}

function Test-SoundOutput {
  try { [Console]::Beep(800,50); return $true } catch { return $false }
}

function Test-DashboardFreshness {
  param([string]$Path=$script:DashboardPath,[TimeSpan]$MaxAge=$script:DashboardMaxAge)
  try {
    if (!(Test-Path $Path)) { return $false }
    $age=(Get-Date)-(Get-Item $Path).LastWriteTime
    return ($age -lt $MaxAge)
  } catch { return $false }
}

function Invoke-CockpitRestart {
  try {
    if (Test-Path $script:StartCockpitScript) {
      Write-WatchdogLog "Relance du cockpit : $($script:StartCockpitScript)"
      Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($script:StartCockpitScript)`"" | Out-Null
      return $true
    } else {
      Write-WatchdogLog "Start-Cockpit.ps1 introuvable" 'ERROR'
      return $false
    }
  } catch {
    Write-WatchdogLog "Echec relance cockpit : $($_.Exception.Message)" 'ERROR'
    return $false
  }
}

function Send-VoiceNotice {
  param([string]$Text='Anomalie dÃ©tectÃ©e. Relance du cockpit.',[switch]$Silent)
  if ($Silent) { return }
  try {
    Add-Type -AssemblyName System.Speech -ErrorAction Stop
    $s = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $s.Rate=-1
    $s.SelectVoiceByHints([System.Speech.Synthesis.VoiceGender]::Female)
    $s.Speak($Text)
  } catch {}
}

function Invoke-WatchdogOnce {
  param([string]$Dashboard=$script:DashboardPath,[TimeSpan]$MaxAge=$script:DashboardMaxAge,[switch]$AutoFix,[switch]$VoiceNotice)
  $status=[ordered]@{
    Timestamp=Get-Date
    CockpitOk=Test-CockpitWindow
    VoiceOk=Test-VoiceEngine
    SoundOk=Test-SoundOutput
    DashOk=Test-DashboardFreshness -Path $Dashboard -MaxAge $MaxAge
    Action='None'
    Details=''
  }
  $problem=-not ($status.CockpitOk -and $status.VoiceOk -and $status.SoundOk -and $status.DashOk)
  if ($problem) {
    $missing=@()
    if (-not $status.CockpitOk){$missing+='Cockpit'}
    if (-not $status.VoiceOk){$missing+='Voice'}
    if (-not $status.SoundOk){$missing+='Sound'}
    if (-not $status.DashOk){$missing+='Dashboard'}
    $msg='Anomalie: '+($missing -join ', ')
    Write-WatchdogLog $msg 'WARN'
    $status.Action='Warn'
    $status.Details=$msg
    if ($AutoFix -and -not $status.CockpitOk){
      if (Invoke-CockpitRestart){
        $status.Action='RestartedCockpit'
        Write-WatchdogLog 'Cockpit relancÃ© automatiquement.'
        if ($VoiceNotice){Send-VoiceNotice -Text 'Anomalie dÃ©tectÃ©e. Relance du cockpit.'}
      }
    }
  } else { Write-WatchdogLog 'OK: Cockpit/Voix/Son/Dashboard conformes.' }
  $script:LastStatus=$status
  [pscustomobject]$status
}

function Start-WatchdogVisual {
  param([int]$IntervalMinutes=$script:DefaultIntervalMinutes,[string]$Dashboard=$script:DashboardPath,[TimeSpan]$MaxAge=$script:DashboardMaxAge,[switch]$AutoFix,[switch]$VoiceNotice)
  if ($script:WatchdogCts) { Write-WatchdogLog 'Watchdog dÃ©jÃ  actif.' 'WARN'; return }
  $script:WatchdogCts=New-Object System.Threading.CancellationTokenSource
  Write-WatchdogLog "Watchdog dÃ©marrÃ© (intervalle=${IntervalMinutes}m)."
  Start-Job -Name 'AthenaWatchdogVisual' -ScriptBlock {
    param($IntervalMinutes,$Dashboard,$MaxAge,$AutoFix,$VoiceNotice,$ModuleDir)
    Import-Module (Join-Path $ModuleDir 'Watchdog.Visual.psm1') -Force | Out-Null
    while ($true) {
      try {
        Invoke-WatchdogOnce -Dashboard $Dashboard -MaxAge $MaxAge -AutoFix:$AutoFix -VoiceNotice:$VoiceNotice | Out-Null
        Start-Sleep -Seconds ([Math]::Max(5,$IntervalMinutes*60))
      } catch {
        Write-WatchdogLog "Boucle Watchdog: $($_.Exception.Message)" 'ERROR'
        Start-Sleep -Seconds 10
      }
    }
  } -ArgumentList $IntervalMinutes,$Dashboard,$MaxAge,$AutoFix,$VoiceNotice,$script:ModuleDir | Out-Null
}

function Stop-WatchdogVisual {
  try {
    $job=Get-Job -Name 'AthenaWatchdogVisual' -ErrorAction SilentlyContinue
    if ($job){Stop-Job $job -Force|Out-Null;Remove-Job $job -Force|Out-Null}
    $script:WatchdogCts=$null
    Write-WatchdogLog "Erreur Ã  l'arrÃªt du Watchdog." 'ERROR'
  } catch {
    Write-WatchdogLog "Erreur lors de l'arrÃªt du Watchdog." 'ERROR'
  }
}

function Get-WatchdogStatus { [pscustomobject]$script:LastStatus }

function Register-AthenaWatchdogTask {
  param([string]$TaskName='Athena_Watchdog',[string]$PwshPath=(Get-Command powershell).Source,[int]$EveryMinutes=5)
  try {
    $action=New-ScheduledTaskAction -Execute $PwshPath -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$($script:StartCockpitScript)`""
    $trigger=New-ScheduledTaskTrigger -Once -At (Get-Date).Date
    $trigger.Repetition=New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSFT_TaskRepetitionPattern',@{Interval="PT${EveryMinutes}M";StopAtDurationEnd=$false}
    $settings=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $principal=New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -RunLevel Highest
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue){Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false|Out-Null}
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal|Out-Null
    Write-WatchdogLog "TÃ¢che planifiÃ©e '$TaskName' crÃ©Ã©e (toutes les ${EveryMinutes} minutes)."
  } catch {Write-WatchdogLog "Erreur crÃ©ation tÃ¢che '$TaskName': $($_.Exception.Message)" 'ERROR'}
}

Export-ModuleMember -Function Start-WatchdogVisual,Stop-WatchdogVisual,Invoke-WatchdogOnce,Get-WatchdogStatus,Register-AthenaWatchdogTask



