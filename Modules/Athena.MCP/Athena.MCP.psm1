# ====================================================================
# ðŸŽ›ï¸ Athena.MCP.psm1  (Main Control Processor)
# Version : v1.1-FusionReady
# Auteur  : Yoann Rousselle / Athena Core
# RÃ´le    : Handler central des messages UI â†’ exÃ©cute des commandes sÃ»res ou des actions
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# Etat interne
$Global:MCP = @{
    Authenticated = $false
    LastMessage   = $null
}

# --------- utilitaires affichage ------------------------------------
function Write-MCP {
    param([string]$Text, [ConsoleColor]$Color = 'Gray')
    $c = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Host $Text
    $Host.UI.RawUI.ForegroundColor = $c
}

# --------- exÃ©cution â€œsafeâ€ (liste blanche) --------------------------
function Invoke-MCPSafe {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Command)

    $allowPatterns = @(
        '^get-date$',
        '^hostname$',
        '^whoami$',
        '^dir(\s+.+)?$',
        '^get-process(\s+-name\s+\S+)?$',
        '^get-service(\s+-name\s+\S+)?$'
    )

    if (-not ($allowPatterns | Where-Object { $Command -match $_ })) {
        return "â›” Commande refusÃ©e (hors liste blanche) : $Command"
    }

    try {
        $result = Invoke-Expression $Command | Out-String
        if ([string]::IsNullOrWhiteSpace($result)) { $result = "(ok)" }
        return $result.Trim()
    }
    catch {
        return "âŒ Erreur exÃ©cution: $($_.Exception.Message)"
    }
}

# --------- Handler branchÃ© sur le serveur ----------------------------
function Register-MCP {
    [CmdletBinding()]
    param()

    # Importe le serveur si nÃ©cessaire
    $serverPath = Join-Path $PSScriptRoot "Athena.ServerCore.psm1"
    if (Test-Path $serverPath) {
        Import-Module $serverPath -Force
    }

    if (-not $Global:AthenaServer.IsRunning) {
        Start-AthenaServer
        Start-Sleep -Milliseconds 200
    }

    # Charge le routeur d'action si dispo
    $actionRouterPath = Join-Path $PSScriptRoot "Athena.ActionRouter.psm1"
    if (Test-Path $actionRouterPath) {
        Import-Module $actionRouterPath -Force
    }

    Register-AthenaMessageHandler -Handler {
        param($Message)
        $Global:MCP.LastMessage = $Message

        if ($Message -eq "auth:$($Global:AthenaServer.Password)") {
            $Global:MCP.Authenticated = $true
            Write-MCP "ðŸ” Auth OK (UI â†’ MCP)" Green
            return
        }

        if (-not $Global:MCP.Authenticated) {
            Write-MCP "ðŸ”’ Message ignorÃ© (non authentifiÃ©) : $Message" DarkYellow
            return
        }

        switch -Regex ($Message) {
            '^ping$' {
                Write-MCP "ðŸ“¡ ping reÃ§u" Cyan
            }
            '^exec:(.+)$' {
                $cmd = $Matches[1].Trim()
                $out = Invoke-MCPSafe $cmd
                Write-MCP "ðŸ› ï¸ exec â†’ $cmd" Magenta
                Write-MCP "$out" Gray
            }
            '^status$' {
                $s = @{
                    Time  = (Get-Date)
                    User  = $env:USERNAME
                    Host  = $env:COMPUTERNAME
                    Pwd   = (Get-Location).Path
                } | ConvertTo-Json -Depth 3
                Write-MCP "ðŸ“Š status : $s" Cyan
            }
            '^action:(.+?):(.+)$' {
                $action = $Matches[1].Trim()
                $param  = $Matches[2].Trim()
                try {
                    $result = Invoke-AthenaAction -Action $action -Param $param
                    Write-MCP "ðŸš€ action:$action exÃ©cutÃ©e â†’ $result" Cyan
                } catch {
                    Write-MCP "âŒ Erreur action:$action â†’ $($_.Exception.Message)" Red
                }
            }
            default {
                Write-MCP "ðŸ“ Message : $Message" White
            }
        }
    }

    Write-MCP "âœ… MCP prÃªt (handler connectÃ© au serveur)." Green
}

Export-ModuleMember -Function Register-MCP


