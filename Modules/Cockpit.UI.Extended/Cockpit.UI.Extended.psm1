# ==============================================================
# Cockpit.UI.Extended.psm1 â€“ K2000 Cockpit (CoreStable)
# Version : 3.0-CoreStable-Universal
# Auteur  : Athena Engine
# Objectif :
#   - Interface cockpit universelle (PowerShell 5 & 7)
#   - Lecture JSON + CPU/RAM temps rÃ©el
#   - Voix synchronisÃ©e toutes les 30s
#   - ZÃ©ro caractÃ¨re spÃ©cial (compatibilitÃ© ASCII)
# ==============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web.Extensions

$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$LogsDir   = Join-Path $RootDir "Logs"
$DataDir   = Join-Path $RootDir "Data"
$Dashboard = Join-Path $DataDir "Cockpit\dashboard.json"
$LogFile   = Join-Path $LogsDir "CockpitUIExtended.log"

if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

function Write-CockpitLog {
    param([string]$Msg,[string]$Level="INFO")
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[$t][$Level] $Msg"
}

function Get-CockpitData {
    if (!(Test-Path $Dashboard)) { return @{score=0;trend="neutral";status="unknown"} }
    try {
        $json = Get-Content $Dashboard -Raw
        $js = New-Object System.Web.Script.Serialization.JavaScriptSerializer
        return $js.DeserializeObject($json)
    } catch {
        Write-CockpitLog "Erreur JSON : $_" "ERROR"
        return @{score=0;trend="neutral";status="error"}
    }
}

function Get-SystemUsage {
    try {
        $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        $ram = (Get-Counter '\Memory\% Committed Bytes In Use').CounterSamples.CookedValue
        return @{cpu=[math]::Round($cpu,0); ram=[math]::Round($ram,0)}
    } catch {
        Write-CockpitLog "Erreur Get-SystemUsage : $_" "WARN"
        return @{cpu=0; ram=0}
    }
}

function Show-CockpitExtended {

    Write-Host "`nDemarrage du Cockpit Athena (v3.0-CoreStable)..." -ForegroundColor Cyan
    Write-CockpitLog "Init cockpit v3.0"

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "ATHENA COCKPIT - K2000 (CoreStable)"
    $form.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
    $form.ForeColor = [System.Drawing.Color]::White
    $form.Width = 960; $form.Height = 620
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $form.FormBorderStyle = 'FixedDialog'

    # --- Titre ---
    $title = New-Object System.Windows.Forms.Label
    $title.Text = "ATHENA COCKPIT"
    $title.Font = New-Object System.Drawing.Font("Consolas",24,[System.Drawing.FontStyle]::Bold)
    $title.ForeColor = 'Red'
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(340,20)
    $form.Controls.Add($title)

    # --- Indicateurs ---
    $lblScore  = New-Object System.Windows.Forms.Label
    $lblTrend  = New-Object System.Windows.Forms.Label
    $lblStatus = New-Object System.Windows.Forms.Label
    $lblCPU    = New-Object System.Windows.Forms.Label
    $lblRAM    = New-Object System.Windows.Forms.Label

    $commonFont = New-Object System.Drawing.Font("Consolas",14,[System.Drawing.FontStyle]::Bold)
    foreach ($l in @($lblScore,$lblTrend,$lblStatus,$lblCPU,$lblRAM)) {
        $l.Font = $commonFont
        $l.AutoSize = $true
        $form.Controls.Add($l)
    }

    $lblScore.Location  = New-Object System.Drawing.Point(100,80)
    $lblTrend.Location  = New-Object System.Drawing.Point(360,80)
    $lblStatus.Location = New-Object System.Drawing.Point(650,80)
    $lblCPU.Location    = New-Object System.Drawing.Point(150,140)
    $lblRAM.Location    = New-Object System.Drawing.Point(600,140)
    $lblCPU.ForeColor = 'DodgerBlue'
    $lblRAM.ForeColor = 'Crimson'

    # --- Barres ---
    $barUser = New-Object System.Windows.Forms.Panel
    $barAthena = New-Object System.Windows.Forms.Panel
    $barUser.Size = $barAthena.Size = New-Object System.Drawing.Size(300,30)
    $barUser.Location = New-Object System.Drawing.Point(150,230)
    $barAthena.Location = New-Object System.Drawing.Point(510,230)
    $barUser.BackColor = 'DodgerBlue'
    $barAthena.BackColor = 'Crimson'
    $form.Controls.AddRange(@($barUser,$barAthena))

    # --- Animation sans Timer WinForms (thread-safe .NET Core) ---
    $job = Start-Job -ScriptBlock {
        while ($true) {
            Start-Sleep -Milliseconds 600
            [System.Windows.Forms.Application]::DoEvents()
        }
    }

    # --- Mise Ã  jour cockpit ---
    function Update-Dashboard {
        $data = Get-CockpitData
        $sys  = Get-SystemUsage
        $lblScore.Text  = "Score : $($data.score)%"
        switch ($data.trend) {
            "up"   { $lblTrend.Text = "Trend : UP";   $lblTrend.ForeColor = 'Lime' }
            "down" { $lblTrend.Text = "Trend : DOWN"; $lblTrend.ForeColor = 'Red' }
            default{ $lblTrend.Text = "Trend : STABLE"; $lblTrend.ForeColor = 'Gray' }
        }
        switch ($data.status) {
            "ok"   { $lblStatus.Text = "Status : OK";   $lblStatus.ForeColor = 'Lime' }
            "warn" { $lblStatus.Text = "Status : WARN"; $lblStatus.ForeColor = 'Yellow' }
            "error"{ $lblStatus.Text = "Status : ERROR";$lblStatus.ForeColor = 'Red' }
            default{ $lblStatus.Text = "Status : ...";  $lblStatus.ForeColor = 'Gray' }
        }
        $lblCPU.Text = "AIR : $($sys.cpu)% CPU"
        $lblRAM.Text = "OIL : $($sys.ram)% RAM"

        if (Get-Command Invoke-AthenaVoice -ErrorAction SilentlyContinue) {
            $etat = switch ($data.status) {
                "ok" {"stable"}; "warn" {"en surveillance"}; "error" {"en anomalie"}; default {"indetermine"}
            }
            $txt = "Etat $etat. CPU $($sys.cpu) pour cent. RAM $($sys.ram) pour cent."
            Invoke-AthenaVoice -Text $txt -Silent
        }
    }

    Update-Dashboard
    $timer = [System.Threading.Timer]::new({ Update-Dashboard }, $null, 30000, 30000)

    Write-CockpitLog "Cockpit affiche (CoreStable)"
    [void]$form.ShowDialog()
    Write-CockpitLog "Fenetre cockpit fermee"

    Stop-Job $job -Force | Out-Null
}

Export-ModuleMember -Function Show-CockpitExtended
Write-Host "Cockpit.UI.Extended.psm1 charge (v3.0-CoreStable-Universal)" -ForegroundColor Green
Write-CockpitLog "Module Cockpit.UI.Extended charge (v3.0-CoreStable-Universal)"



