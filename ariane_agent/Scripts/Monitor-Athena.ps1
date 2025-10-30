# ====================================================================
# Monitor-Athena.ps1 — Surveillance & Auto-Restart (Phase 8)
# ====================================================================
param(
    [string]$ConfigPath = "C:/Ariane-Agent/config/services.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

function Write-Log {
    param([string]$Message)
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$ts] [Monitor] $Message"
    if ($script:LogFile) {
        $dir = Split-Path $script:LogFile -Parent
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Add-Content -Path $script:LogFile -Value $line
    }
    Write-Host $line
}

function Rotate-LogIfNeeded {
    try {
        if (Test-Path $script:LogFile) {
            $lenMB = (Get-Item $script:LogFile).Length / 1MB
            if ($lenMB -gt $script:LogMaxMB) {
                $bak = "$($script:LogFile).bak_" + (Get-Date -Format 'yyyyMMdd_HHmmss')
                Move-Item -Force $script:LogFile $bak
                Write-Log "Rotation log → $bak"
            }
        }
    } catch {}
}

function Invoke-Say {
    param([string]$Text)
    if (-not $script:SpeakUrl) { return }
    try {
        Invoke-RestMethod -Uri $script:SpeakUrl -Method Post -Body @{ text = $Text } -ErrorAction Stop | Out-Null
    } catch {
        Write-Log "TTS indisponible: $($_.Exception.Message)"
    }
}

function Test-TcpPort {
    param([int]$Port)
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect('127.0.0.1', $Port, $null, $null)
        $ok = $iar.AsyncWaitHandle.WaitOne(1000)
        if ($ok -and $client.Connected) { 
            $client.Close()
            return $true 
        }
        $client.Close()
        return $false
    } catch {
        return $false
    }
}

function Test-Http {
    param([string]$Url,[int]$Expect=200)
    try {
        $resp = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 3 -UseBasicParsing
        return ($resp.StatusCode -eq $Expect)
    } catch { 
        return $false 
    }
}

function Restart-ServiceEntry {
    param($svc)
    Write-Log "Relance demandée: $($svc.name) via: $($svc.restart_cmd)"
    try {
        Start-Process -FilePath powershell -ArgumentList "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -Command `"$($svc.restart_cmd)`"" -WindowStyle Hidden | Out-Null
        $cooldownSec = [int]($script:Cooldown)
Start-Sleep -Seconds $cooldownSec
        Write-Log "Relance effectuée: $($svc.name)"
        Invoke-Say "Relance du service $($svc.name) effectuée."
    } catch {
        Write-Log "ERREUR relance $($svc.name): $($_.Exception.Message)"
        Invoke-Say "Échec relance du service $($svc.name)."
    }
}

# --- Chargement config ---
if (-not (Test-Path $ConfigPath)) { throw "Config introuvable: $ConfigPath" }
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$script:LogFile  = $config.global.log_file
$script:SpeakUrl = $config.global.speak_url
$script:Interval = [int]$config.global.check_interval_sec
$script:Cooldown = [int]$config.global.cooldown_after_restart_sec
$script:LogMaxMB = [int]$config.global.log_max_mb
$services        = $config.services

Rotate-LogIfNeeded
Write-Log "Démarrage Monitor-Athena.ps1 (interval=$($script:Interval)s)"
Invoke-Say "Surveillance Athena activée."

while ($true) {
    foreach ($svc in $services) {
        $ok = $false
        switch ($svc.method) {
            'http' { $ok = Test-Http -Url $svc.url -Expect ([int]$svc.expect_code) }
            'tcp'  { $ok = Test-TcpPort -Port ([int]$svc.port) }
            'process' { $ok = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "$($svc.process_hint)*" }).Count -gt 0 }
            default { $ok = $false }
        }

        if (-not $ok) {
            Write-Log "DOWN détecté: $($svc.name). Tentative de relance..."
            $attempts = [int]$svc.retries
            for ($i=1; $i -le $attempts; $i++) {
                Restart-ServiceEntry -svc $svc
                Start-Sleep -Milliseconds 800
                switch ($svc.method) {
                    'http' { $ok = Test-Http -Url $svc.url -Expect ([int]$svc.expect_code) }
                    'tcp'  { $ok = Test-TcpPort -Port ([int]$svc.port) }
                    'process' { $ok = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "$($svc.process_hint)*" }).Count -gt 0 }
                }
                if ($ok) { Write-Log "OK après relance: $($svc.name)"; break }
            }
            if (-not $ok) {
                Write-Log "ECHEC après $attempts tentative(s): $($svc.name)"
                Invoke-Say "Alerte critique : $($svc.name) ne redémarre pas."
            }
        } else {
            Write-Log "OK: $($svc.name)"
        }
    }

    Rotate-LogIfNeeded
    Start-Sleep -Seconds $script:Interval
}
