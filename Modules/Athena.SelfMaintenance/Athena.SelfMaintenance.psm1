# ============================================================
# ðŸ§  Athena.SelfMaintenance.psm1
# Version : v1.0-Stable-Final
# RÃ´le    : Surveillance, rÃ©paration et relance automatique
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$RootDir   = Split-Path -Parent $PSScriptRoot
$LogDir    = Join-Path $RootDir "Logs"
$ScriptDir = Join-Path $RootDir "Scripts"
$ModDir    = Join-Path $RootDir "Modules"
$MemoryDir = Join-Path $RootDir "Memory"

if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$LogFile = Join-Path $LogDir "Athena_SelfMaintenance.log"

function Write-SelfLog {
    param([string]$Msg,[string]$Level="INFO")
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$time][$Level] $Msg"
}

# ============================================================
# ðŸ” VÃ©rification des scripts et modules critiques
# ============================================================
function Test-AthenaCoreIntegrity {
    Write-SelfLog "DÃ©marrage vÃ©rification intÃ©gritÃ©..."
    $core = @(
        "Cockpit.Sync.psm1",
        "Start-CockpitLite.ps1",
        "Athena.SelfMaintenance.psm1"
    )

    foreach ($f in $core) {
        $path = if ($f -like "*.ps1") { Join-Path $ScriptDir $f } else { Join-Path $ModDir $f }
        if (!(Test-Path $path)) {
            Write-SelfLog "âŒ Fichier manquant : $f" "WARN"
            Invoke-AthenaSelfRepair -MissingFile $f
        }
        else {
            Write-SelfLog "âœ… $f vÃ©rifiÃ©."
        }
    }
}

# ============================================================
# ðŸ§© Auto-rÃ©paration de fichiers manquants
# ============================================================
function Invoke-AthenaSelfRepair {
    param([string]$MissingFile)

    $name = [IO.Path]::GetFileName($MissingFile)
    $dest = if ($name -like "*.ps1") { Join-Path $ScriptDir $name } else { Join-Path $ModDir $name }

    Write-SelfLog "Tentative de rÃ©gÃ©nÃ©ration de $name..."
    switch -Regex ($name) {

        "Start-CockpitLite.ps1" {
            $content = @"
# Copie d'urgence rÃ©gÃ©nÃ©rÃ©e par SelfMaintenance
param([int]\$Port=9191)
\$RootDir  = '$env:ARIANE_ROOT'
\$WebUI    = "\$RootDir\\WebUI"
\$listener = [System.Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,\$Port)
try{\$listener.Start()}catch{exit}
while(\$true){
  \$c=\$listener.AcceptTcpClient();\$s=\$c.GetStream();\$r=New-Object IO.StreamReader(\$s)
  \$req="";while(\$r.Peek() -ne -1){\$l=\$r.ReadLine();if(\$l -eq ""){break};\$req+=\$l+"`n"}
  if(\$req -match "GET /(.*?) "){\$f=\$matches[1];if([string]::IsNullOrWhiteSpace(\$f)){\$f="index.html"}
    if(\$f -like "Memory/*"){\$p=Join-Path \$RootDir \$f}else{\$p=Join-Path \$WebUI \$f}}
  else{\$p=Join-Path \$WebUI "index.html"}
  if(Test-Path \$p){\$b=[IO.File]::ReadAllBytes(\$p);\$ext=[IO.Path]::GetExtension(\$p).ToLower();
    switch(\$ext){".css"{\$ct="text/css"}".js"{\$ct="application/javascript"}".wav"{\$ct="audio/wav"}default{\$ct="text/html"}}
    \$h="HTTP/1.1 200 OK`r`nContent-Type: \$ct`r`nContent-Length: \$(\$b.Length)`r`n`r`n"
    \$hb=[Text.Encoding]::ASCII.GetBytes(\$h);try{\$s.Write(\$hb,0,\$hb.Length);\$s.Write(\$b,0,\$b.Length)}catch{}}
  else{\$msg="<h1>404 â€“ Fichier introuvable</h1>";\$b=[Text.Encoding]::UTF8.GetBytes("HTTP/1.1 404 Not Found`r`nContent-Type:text/html`r`n`r`n\$msg");try{\$s.Write(\$b,0,\$b.Length)}catch{}}
  \$s.Close();\$c.Close()}
"@
            $content | Out-File -Encoding UTF8 $dest
            Write-SelfLog "âœ… $name rÃ©gÃ©nÃ©rÃ© automatiquement."
        }

        "Cockpit.Sync.psm1" {
            Write-SelfLog "âš™ï¸  Cockpit.Sync.psm1 manquant : rÃ©gÃ©nÃ©ration non autorisÃ©e (module critique)." "WARN"
        }

        default {
            Write-SelfLog "Aucune rÃ¨gle de reconstruction pour $name." "WARN"
        }
    }
}

# ============================================================
# ðŸ”„ RedÃ©marrage automatique du serveur cockpit
# ============================================================
function Restart-CockpitServer {
    param([int]$Port = 9191)
    try {
        $proc = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
        if ($proc) {
            Stop-Process -Id $proc.OwningProcess -Force -ErrorAction SilentlyContinue
            Write-SelfLog "Port $Port libÃ©rÃ©."
        }
        $script = Join-Path $ScriptDir "Start-CockpitLite.ps1"
        Start-Process pwsh -ArgumentList "-NoLogo -WindowStyle Hidden -File `"$script`""
        Write-SelfLog "RedÃ©marrage du serveur CockpitLite sur port $Port."
    } catch {
        Write-SelfLog "Erreur lors du redÃ©marrage du serveur : $_" "ERROR"
    }
}

# ============================================================
# â™»ï¸ VÃ©rification des ports critiques
# ============================================================
function Test-AthenaPorts {
    $ports = 9091,9191
    foreach ($p in $ports) {
        $c = Test-NetConnection -ComputerName localhost -Port $p -WarningAction SilentlyContinue
        if (-not $c.TcpTestSucceeded) {
            Write-SelfLog "âš ï¸  Port $p inactif. Tentative de relance."
            if ($p -eq 9191) { Restart-CockpitServer -Port 9191 }
        } else {
            Write-SelfLog "âœ… Port $p actif."
        }
    }
}

# ============================================================
# ðŸ§  Routine principale
# ============================================================
function Invoke-AthenaSelfMaintenance {
    Write-Host "`nðŸ§   DÃ©marrage auto-maintenance Athena..." -ForegroundColor Cyan
    Write-SelfLog "=== Cycle auto-maintenance lancÃ© ==="
    Test-AthenaCoreIntegrity
    Test-AthenaPorts
    Write-SelfLog "=== Cycle auto-maintenance terminÃ© ==="
    Write-Host "âœ…  Auto-maintenance terminÃ©e.`n" -ForegroundColor Green
}

Export-ModuleMember -Function Invoke-AthenaSelfMaintenance, Restart-CockpitServer, Test-AthenaCoreIntegrity
Write-Host "ðŸ§   Module Athena.SelfMaintenance.psm1 chargÃ© (v1.0-Stable-Final)" -ForegroundColor Yellow
Write-SelfLog "Module chargÃ© avec succÃ¨s."


