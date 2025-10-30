# ====================================================================
# Cockpit.UI.psm1 ï¿½ Interface visuelle K2000 (v6.5-DreamSwitch-FullCycle)
# Compatible PowerShell 5.x et 7.x (sans emoji ni accent)
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# --------------------------------------------------------------------
# Import automatique du module de donnees
# --------------------------------------------------------------------
$DataModulePath = Join-Path $PSScriptRoot "Cockpit.Data.psm1"
if (Test-Path $DataModulePath) {
    Import-Module $DataModulePath -Force -Global
    Write-Host "Cockpit.Data.psm1 importe automatiquement."
} else {
    Write-Warning "Module Cockpit.Data.psm1 introuvable."
}

Add-Type -AssemblyName PresentationFramework
$LogsDir = Join-Path (Split-Path -Parent $PSScriptRoot) "Logs"
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
$UILog = Join-Path $LogsDir "Cockpit.UI.log"

function Write-UILog {
    param([string]$Msg)
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $UILog -Value "[$t] $Msg"
}

# --------------------------------------------------------------------
# Mise a jour visuelle du cockpit
# --------------------------------------------------------------------
function Update-CockpitDisplay {
    param([string]$Signal)
    if (-not $global:window -or -not ($global:window.Dispatcher)) { return }

    $global:window.Dispatcher.Invoke([action]{
        switch ($Signal) {
            "UserSpeaking" {
                $global:barUser.Fill   = New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString("#0066FF"))
                $global:barAthena.Fill = New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString("#222"))
            }
            "AthenaThinking" {
                $global:barUser.Fill   = New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString("#222"))
                $global:barAthena.Fill = New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString("#FF9900"))
            }
            "AthenaSpeaking" {
                $global:barUser.Fill   = New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString("#222"))
                $global:barAthena.Fill = New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString("#FF0000"))
            }
            "Idle" {
                $global:barUser.Fill   = New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString("#222"))
                $global:barAthena.Fill = New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString("#222"))
            }
            "Error" {
                $global:barUser.Fill   = New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString("#880088"))
                $global:barAthena.Fill = New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString("#880088"))
            }
        }
    })
}

# --------------------------------------------------------------------
# Affichage principal du cockpit
# --------------------------------------------------------------------
function Show-CockpitUI {
    if (-not $global:ArianeIADriver) { $global:ArianeIADriver = "auto" }

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Athena Cockpit K2000"
        Height="380" Width="660" WindowStartupLocation="CenterScreen" Background="#111">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Bandeau supï¿½rieur -->
        <DockPanel Grid.Row="0" LastChildFill="False">
            <TextBlock Text="ATHENA COCKPIT K2000 - v6.5" 
                       Foreground="#FF2222" FontSize="20"
                       VerticalAlignment="Center" Margin="10,0,0,0" DockPanel.Dock="Left"/>
            <StackPanel Orientation="Horizontal" DockPanel.Dock="Right" Margin="0,8,10,8">
                <Button Name="BtnWake" Content="Reveiller" Width="120" Height="28"
                        Background="#333" Foreground="White" FontWeight="Bold"
                        ToolTip="Reveiller Athena (Start-AthenaWake.ps1)"/>
                <Button Name="BtnSleep" Content="Mettre en veille" Width="150" Height="28"
                        Background="#222" Foreground="White" FontWeight="Bold"
                        Margin="10,0,0,0" ToolTip="Mettre Athena en veille douce"/>
            </StackPanel>
        </DockPanel>

        <!-- Barres voix -->
        <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,10">
            <Rectangle Name="BarVoiceUser" Width="220" Height="12" Fill="#222" RadiusX="4" RadiusY="4" Margin="5"/>
            <Rectangle Name="BarVoiceAthena" Width="220" Height="12" Fill="#222" RadiusX="4" RadiusY="4" Margin="5"/>
        </StackPanel>

        <!-- Zone centrale -->
        <StackPanel Grid.Row="2" Orientation="Vertical" HorizontalAlignment="Center">
            <ProgressBar Name="BarCPU" Height="20" Margin="0,5" Maximum="100"/>
            <ProgressBar Name="BarRAM" Height="20" Margin="0,5" Maximum="100"/>
            <TextBlock Name="TxtStatus" Foreground="White" FontSize="14" TextAlignment="Center" Margin="0,5"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,10,0,0">
                <Button Name="BtnAuto" Content="AUTO" Width="90" Margin="5"/>
                <Button Name="BtnNormal" Content="NORMAL" Width="90" Margin="5"/>
                <Button Name="BtnPursuit" Content="PURSUIT" Width="90" Margin="5"/>
            </StackPanel>
        </StackPanel>
    </Grid>
</Window>
"@

    $reader  = New-Object System.Xml.XmlNodeReader $xaml
    $window  = [Windows.Markup.XamlReader]::Load($reader)

    $global:barCPU    = $window.FindName("BarCPU")
    $global:barRAM    = $window.FindName("BarRAM")
    $global:txtStatus = $window.FindName("TxtStatus")
    $global:barUser   = $window.FindName("BarVoiceUser")
    $global:barAthena = $window.FindName("BarVoiceAthena")
    $global:window    = $window

    $btnAuto    = $window.FindName("BtnAuto")
    $btnNormal  = $window.FindName("BtnNormal")
    $btnPursuit = $window.FindName("BtnPursuit")
    $btnSleep   = $window.FindName("BtnSleep")
    $btnWake    = $window.FindName("BtnWake")

    # ----------------------------------------------------------
    # Bouton "Mettre en veille"
    # ----------------------------------------------------------
    $btnSleep.Add_Click({
        try {
            $global:txtStatus.Text = "Athena passe en veille douce..."
            Write-UILog "Bouton veille clique."
            $sleepMod = Join-Path (Split-Path -Parent $PSScriptRoot) "Modules\Athena.Sleep.psm1"
            if (Test-Path $sleepMod) {
                Import-Module $sleepMod -Force -Global
                Invoke-AthenaSleep
            } else {
                [System.Windows.MessageBox]::Show("Module Athena.Sleep.psm1 introuvable.","Erreur","OK","Error")
                Write-UILog "Module Athena.Sleep introuvable."
            }
        } catch {
            [System.Windows.MessageBox]::Show("Erreur pendant la mise en veille : $_","Erreur","OK","Error")
            Write-UILog "Erreur Invoke-AthenaSleep : $_"
        }
    })

    # ----------------------------------------------------------
    # Bouton "Reveiller"
    # ----------------------------------------------------------
    $btnWake.Add_Click({
        try {
            $global:txtStatus.Text = "Reveil d'Athena en cours..."
            Write-UILog "Bouton reveil clique."
            $wakeScript = Join-Path (Split-Path -Parent $PSScriptRoot) "Start-AthenaWake.ps1"
            if (Test-Path $wakeScript) {
                Write-Host "Demarrage du script de reveil..." -ForegroundColor Cyan
                Start-Job -Name "AthenaWake" -ScriptBlock { & $using:wakeScript } | Out-Null
            } else {
                [System.Windows.MessageBox]::Show("Script Start-AthenaWake.ps1 introuvable.","Erreur","OK","Error")
                Write-UILog "Script Start-AthenaWake.ps1 introuvable."
            }
        } catch {
            [System.Windows.MessageBox]::Show("Erreur pendant le reveil : $_","Erreur","OK","Error")
            Write-UILog "Erreur Start-AthenaWake : $_"
        }
    })

    # ----------------------------------------------------------
    # Modes IA
    # ----------------------------------------------------------
    $btnAuto.Add_Click({ $global:ArianeIADriver = "auto";    $txtStatus.Text = "Mode IA : AUTO" })
    $btnNormal.Add_Click({ $global:ArianeIADriver = "normal"; $txtStatus.Text = "Mode IA : NORMAL" })
    $btnPursuit.Add_Click({ $global:ArianeIADriver = "pursuit";$txtStatus.Text = "Mode IA : PURSUIT" })

    # ----------------------------------------------------------
    # Timer CPU/RAM
    # ----------------------------------------------------------
    $global:timer = New-Object Windows.Threading.DispatcherTimer
    $global:timer.Interval = [TimeSpan]::FromSeconds(2)
    $global:timer.Add_Tick({
        try {
            if (Get-Command Get-CockpitData -ErrorAction SilentlyContinue) {
                $data = Get-CockpitData
                $barCPU.Value = [double]($data.CPU -replace '[^0-9.]','')
                $barRAM.Value = [double]($data.RAM -replace '[^0-9.]','')
                $txtStatus.Text = "CPU: $($data.CPU) RAM: $($data.RAM) Modules: $($data.Modules)"
            }
        } catch { }
    })
    $window.Add_ContentRendered({ Start-Sleep -Milliseconds 500; try { $global:timer.Start() } catch { } })

    try { $window.ShowDialog() | Out-Null }
    catch { Write-Warning "Cockpit UI ferme ou interrompu : $($_.Exception.Message)" }
}

Export-ModuleMember -Function Show-CockpitUI, Update-CockpitDisplay
Write-Host "Cockpit.UI.psm1 charge (v6.5-DreamSwitch-FullCycle)."
Write-UILog "Module Cockpit.UI charge (v6.5-DreamSwitch-FullCycle)."



