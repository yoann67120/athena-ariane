# ====================================================================
# ðŸ§© Cockpit.CycleMonitor.psm1 â€“ Visualisation temps rÃ©el du cycle
# Version : v1.0-KITT-Chronos-Edition
# ====================================================================
# Objectif :
#   - Afficher le cycle jour/nuit dâ€™Athena en temps rÃ©el
#   - Indiquer lâ€™Ã©tat courant : RÃ©veil / Actif / RÃªve
#   - Synchroniser la couleur et lâ€™animation avec Cockpit.Signal
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

Add-Type -AssemblyName PresentationFramework

$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ModuleDir
$LogsDir   = Join-Path $RootDir "Logs"
$UIlog     = Join-Path $LogsDir "CockpitCycleMonitor.log"

function Write-MonitorLog {
    param([string]$Msg)
    $t = (Get-Date).ToString("HH:mm:ss")
    Add-Content -Path $UIlog -Value "[$t] $Msg"
}

# --------------------------------------------------------------------
# âš™ï¸ Interface WPF
# --------------------------------------------------------------------
function Show-CycleMonitor {
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Athena Cycle Monitor" Width="500" Height="500" Background="#111">
    <Grid>
        <Ellipse Name="cycleRing" Width="300" Height="300" Stroke="#00AAFF" StrokeThickness="10" Opacity="0.8"/>
        <TextBlock Name="txtStatus" Text="Cycle..." Foreground="White" FontSize="24"
                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
        <TextBlock Name="txtTime" Foreground="LightGray" FontSize="16"
                   HorizontalAlignment="Center" VerticalAlignment="Bottom" Margin="0,0,0,40"/>
    </Grid>
</Window>
"@

    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)

    $cycleRing = $window.FindName("cycleRing")
    $txtStatus = $window.FindName("txtStatus")
    $txtTime   = $window.FindName("txtTime")

    # Animation circulaire de couleur
    $anim = New-Object Windows.Media.Animation.ColorAnimation
    $anim.From = [Windows.Media.Colors]::Blue
    $anim.To   = [Windows.Media.Colors]::Orange
    $anim.Duration = [Windows.Duration]::new([TimeSpan]::FromSeconds(6))
    $anim.AutoReverse = $true
    $anim.RepeatBehavior = [Windows.Media.Animation.RepeatBehavior]::Forever

    $brush = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Colors]::Blue)
    $cycleRing.Stroke = $brush
    $brush.BeginAnimation([Windows.Media.SolidColorBrush]::ColorProperty, $anim)

    # Boucle de mise Ã  jour temps rÃ©el
    $timer = New-Object Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(5)
    $timer.Add_Tick({
        $now = Get-Date
        $hour = $now.Hour
        $txtTime.Text = $now.ToString("HH:mm:ss")

        switch ($hour) {
            {$_ -ge 6 -and $_ -lt 8} {
                $txtStatus.Text = "ðŸŒ… RÃ©veil dâ€™Athena"
                $brush.Color = [Windows.Media.Colors]::Orange
            }
            {$_ -ge 8 -and $_ -lt 22} {
                $txtStatus.Text = "ðŸ§  Cycle Journalier"
                $brush.Color = [Windows.Media.Colors]::DodgerBlue
            }
            {$_ -ge 22 -or $_ -lt 6} {
                $txtStatus.Text = "ðŸŒ™ RÃªve et Apprentissage"
                $brush.Color = [Windows.Media.Colors]::Purple
            }
        }
        Write-MonitorLog "Maj UI â†’ $($txtStatus.Text)"
    })
    $timer.Start()

    Write-Host "ðŸŽ›ï¸ Lancement du tableau de bord du cycle..." -ForegroundColor Cyan
    $window.ShowDialog() | Out-Null
}

Export-ModuleMember -Function Show-CycleMonitor
Write-Host "ðŸ§© Cockpit.CycleMonitor.psm1 chargÃ© (v1.0-KITT-Chronos-Edition)" -ForegroundColor Yellow
Write-MonitorLog "Module CycleMonitor initialisÃ©"



