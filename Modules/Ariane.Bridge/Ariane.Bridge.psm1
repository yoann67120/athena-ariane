# ===============================================
# Ariane.Bridge.psm1
# Pont PowerShell <-> Agent local (Flask)
# Securise, sans caracteres speciaux/emoji
# ===============================================

function Test-ArianeAgent {
    [CmdletBinding()]
    param(
        [string]$AgentUrl = "http://localhost:5000",
        [int]$Port = 5000,
        [int]$TimeoutSec = 2
    )
    try {
        $tcp = Test-NetConnection -ComputerName "127.0.0.1" -Port $Port -WarningAction SilentlyContinue
        if (-not $tcp.TcpTestSucceeded) { return $false }
        return $true
    } catch { return $false }
}

function Invoke-Ariane {
    <#
      .SYNOPSIS
        Envoie un prompt a l'agent local et affiche le resultat.
      .PARAMETER Prompt
        Instruction en langage naturel.
      .PARAMETER Mode
        auto | text | code (par defaut: auto)
      .PARAMETER AgentUrl
        URL de l'agent Flask.
      .PARAMETER TimeoutSec
        Delai max pour l'appel HTTP.
      .EXAMPLE
        Invoke-Ariane -Prompt "Cree un module Hello.psm1 qui affiche 'OK'"
      .EXAMPLE
        Invoke-Ariane -Prompt "Analyse mon dossier et propose un plan" -Mode text
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Prompt,
        [ValidateSet("auto","text","code")][string]$Mode = "auto",
        [string]$AgentUrl = "http://localhost:5000/execute",
        [int]$TimeoutSec = 60
    )

    if (-not (Test-ArianeAgent -AgentUrl $AgentUrl -TimeoutSec 2)) {
        Write-Host "Agent local inactif (port 5000). Lancez:  cd C:\Ariane-Agent ; python agent.py" -ForegroundColor Red
        return
    }

    # Forcer le mode par prefixe pour aider l'agent a repondre correctement
    $effectivePrompt = $Prompt
    switch ($Mode) {
        "text" {
            $effectivePrompt = "Ne cree pas de module. Reponds uniquement en texte clair et concis en francais. " + $Prompt
        }
        "code" {
            $effectivePrompt = "Genere uniquement du code PowerShell pur, sans markdown ni explications. " + $Prompt
        }
        default { } # auto
    }

    try {
        $bodyObj = @{ prompt = $effectivePrompt }
        $json = $bodyObj | ConvertTo-Json -Depth 6
        $resp = Invoke-RestMethod -Uri $AgentUrl -Method POST -Body $json -ContentType "application/json" -TimeoutSec $TimeoutSec

        # Affichage standardise
        if ($resp.message) {
            Write-Host $resp.message -ForegroundColor Green
        }
        if ($resp.stdout) {
            Write-Host ""
            Write-Host "----- Sortie -----" -ForegroundColor Yellow
            Write-Host ($resp.stdout | Out-String)
        }
        if ($resp.stderr) {
            Write-Host ""
            Write-Host "----- Erreurs -----" -ForegroundColor Red
            Write-Host ($resp.stderr | Out-String)
        }
        if ($resp.execution_time -ne $null) {
            Write-Host ""
            Write-Host ("Delai d'execution: {0}s" -f $resp.execution_time) -ForegroundColor DarkGray
        }
    }
    catch {
        $msg = $_.Exception.Message
        Write-Host "Echec d'appel a l'agent: $msg" -ForegroundColor Red

        # Si l'agent a renvoye un JSON d'erreur, essayons de l'afficher
        if ($_.Exception.Response) {
            try {
                $stream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $raw = $reader.ReadToEnd()
                if ($raw) {
                    Write-Host ""
                    Write-Host "Reponse brute de l'agent:" -ForegroundColor DarkYellow
                    Write-Host $raw
                }
            } catch { }
        }
    }
}

Export-ModuleMember -Function Invoke-Ariane,Test-ArianeAgent
