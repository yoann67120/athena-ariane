# ====================================================================
# ðŸŒ Athena.API.psm1 â€“ v1.0-LocalREST-Secure
# --------------------------------------------------------------------
# Auteur : Yoann Rousselle / Athena Core
# --------------------------------------------------------------------
# RÃ´le :
#   - Serveur REST local pour communication inter-IA et cockpit
#   - ContrÃ´le : statut, exÃ©cution, mise Ã  jour AutoDeploy
#   - Journalisation et sandbox sÃ©curitÃ©
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# === Dossiers ======================================================
$RootDir     = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$LogsDir     = Join-Path $RootDir 'Logs'
$ModulesDir  = Join-Path $RootDir 'Modules'
$MemoryDir   = Join-Path $RootDir 'Memory'

if (!(Test-Path $LogsDir))  { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
if (!(Test-Path $MemoryDir)){ New-Item -ItemType Directory -Path $MemoryDir -Force | Out-Null }

$ApiLog = Join-Path $LogsDir 'Athena.API.log'

# ====================================================================
# âœï¸ Log
# ====================================================================
function Write-ApiLog {
    param([string]$Msg,[string]$Level='INFO')
    $t=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $ApiLog -Value "[$t][$Level] $Msg"
}

# ====================================================================
# ðŸ§  Obtenir lâ€™Ã©tat dâ€™Athena
# ====================================================================
function Get-AthenaStatus {
    try {
        $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        $ram = (Get-CimInstance Win32_OperatingSystem)
        $ramUsedPct = [math]::Round((($ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory)/$ram.TotalVisibleMemorySize)*100,2)
        $status = [ordered]@{
            Time   = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            CPU    = [math]::Round($cpu,2)
            RAM    = $ramUsedPct
            Modules= (Get-ChildItem $ModulesDir -Filter '*.psm1').Count
        }
        return $status
    } catch {
        return @{ error = $_.Exception.Message }
    }
}

# ====================================================================
# âš™ï¸ ExÃ©cution sÃ©curisÃ©e (sandbox)
# ====================================================================
function Invoke-AthenaSandboxCommand {
    param([string]$Command)
    try {
        if ($Command -match 'Remove-|Restart-|Stop-|Format-|Set-ExecutionPolicy') {
            return @{ error = 'Commande refusÃ©e (sÃ©curitÃ©)' }
        }
        $result = Invoke-Expression $Command | Out-String
        return @{ result = $result.Trim() }
    } catch {
        return @{ error = $_.Exception.Message }
    }
}

# ====================================================================
# ðŸš€ Lancement du serveur REST
# ====================================================================
function Start-AthenaAPIServer {
    param([int]$Port = 49393)

    Write-Host "`nðŸŒ DÃ©marrage du serveur REST Athena sur le port $Port..." -ForegroundColor Cyan
    Write-ApiLog "DÃ©marrage du serveur REST sur le port $Port"

    try {
        $listener = [System.Net.HttpListener]::new()
        $listener.Prefixes.Add("http://*:$Port/")
        $listener.Start()
        Write-Host "âœ… Serveur REST actif sur http://localhost:$Port/" -ForegroundColor Green
    } catch {
        Write-Host "âŒ Erreur de dÃ©marrage : $($_.Exception.Message)" -ForegroundColor Red
        Write-ApiLog "Erreur dÃ©marrage serveur : $($_.Exception.Message)"
        return
    }

    while ($listener.IsListening) {
        try {
            $context  = $listener.GetContext()
            $request  = $context.Request
            $response = $context.Response
            $path     = $request.Url.AbsolutePath.ToLower()
            Write-ApiLog "RequÃªte : $path"

            switch -Regex ($path) {

                # --- GET /api/status ---
                "^/api/status$" {
                    $status = Get-AthenaStatus
                    $json = $status | ConvertTo-Json -Depth 4
                    $bytes=[System.Text.Encoding]::UTF8.GetBytes($json)
                    $response.ContentType='application/json'
                    $response.OutputStream.Write($bytes,0,$bytes.Length)
                    $response.Close()
                    continue
                }

                # --- POST /api/execute ---
                "^/api/execute$" {
                    $reader = New-Object System.IO.StreamReader($request.InputStream)
                    $body = $reader.ReadToEnd()
                    $data = $body | ConvertFrom-Json
                    $cmd  = $data.command
                    Write-ApiLog "Execution : $cmd"
                    $res = Invoke-AthenaSandboxCommand -Command $cmd
                    $json = $res | ConvertTo-Json -Depth 5
                    $bytes=[System.Text.Encoding]::UTF8.GetBytes($json)
                    $response.ContentType='application/json'
                    $response.OutputStream.Write($bytes,0,$bytes.Length)
                    $response.Close()
                    continue
                }

                # --- POST /api/update ---
                "^/api/update$" {
                    Write-ApiLog "DÃ©clenchement AutoDeploy"
                    try {
                        Import-Module (Join-Path $ModulesDir 'Athena.AutoDeploy.psm1') -Force -Global | Out-Null
                        Invoke-AthenaAutoDeploy
                        $reply=@{ status='AutoDeploy dÃ©clenchÃ©' }
                    } catch {
                        $reply=@{ error="Echec du dÃ©clenchement AutoDeploy : $_" }
                    }
                    $json=$reply|ConvertTo-Json
                    $bytes=[System.Text.Encoding]::UTF8.GetBytes($json)
                    $response.ContentType='application/json'
                    $response.OutputStream.Write($bytes,0,$bytes.Length)
                    $response.Close()
                    continue
                }

                default {
                    $msg = "404 â€“ Endpoint inconnu : $path"
                    Write-ApiLog $msg 'WARN'
                    $bytes=[System.Text.Encoding]::UTF8.GetBytes($msg)
                    $response.StatusCode=404
                    $response.OutputStream.Write($bytes,0,$bytes.Length)
                    $response.Close()
                }
            }
        } catch {
            Write-ApiLog "Erreur requÃªte : $_" 'ERROR'
        }
    }

    $listener.Stop()
    Write-ApiLog "Serveur REST arrÃªtÃ© proprement."
}

# ====================================================================
# ðŸ”š Export
# ====================================================================
Export-ModuleMember -Function Start-AthenaAPIServer, Get-AthenaStatus, Invoke-AthenaSandboxCommand
Write-Host "ðŸŒ Module Athena.API.psm1 chargÃ© (v1.0-LocalREST-Secure)" -ForegroundColor Cyan
Write-ApiLog "Module Athena.API.psm1 chargÃ© (v1.0-LocalREST-Secure)"
# ====================================================================


