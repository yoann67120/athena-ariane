# ====================================================================
# ðŸŒ SYNCHRONISATION COCKPIT â€“ WebSocket + Fallback local
# Version : v3.5 â€“ WebUI Full Interactive Bridge
# ====================================================================

function Send-ToCockpit {
    param(
        [string]$Message,
        [string]$Type = "Athena"
    )

    try {
        $socketPort = 9191
        $uri = "ws://localhost:$socketPort"
        $json = @{
            source = $Type
            message = $Message
            timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        } | ConvertTo-Json -Depth 3

        # Si Cockpit.Sync est actif â†’ utiliser sa fonction directe
        if (Get-Command Send-CockpitMessage -ErrorAction SilentlyContinue) {
            Send-CockpitMessage -JsonPayload $json
            return
        }

        # Sinon fallback : Ã©criture JSON pour rÃ©cupÃ©ration pÃ©riodique
        $outPath = "$env:ARIANE_ROOT\WebUI\last_message.json"
        Set-Content -Path $outPath -Value $json -Encoding UTF8

        # Message console pour debug
        [System.Console]::WriteLine("ðŸŒ Message envoyÃ© au cockpit : {0}" -f $Message)
    }
    catch {
        [System.Console]::WriteLine("âš ï¸ Erreur Send-ToCockpit : {0}" -f $_.Exception.Message)
    }
}

# === Patch Invoke-AthenaDialogue pour inclure Cockpit Sync ===
Remove-Item Function:\Invoke-AthenaDialogue -ErrorAction SilentlyContinue

function Invoke-AthenaDialogue {
    param([string]$Input)

    if ([string]::IsNullOrWhiteSpace($Input)) { return }

    $Global:Athena_LastCommand = $Input
    [Console]::WriteLine("ðŸ—£ï¸ Toi : {0}" -f $Input)
    Send-ToCockpit -Message $Input -Type "User"

    Update-EmotionState "Ã‰coute"
    Update-CockpitState -Status "Analyse cognitive" -LastAction "InterprÃ©tation en cours..." -Progress 12

    try {
        # --- Appel du moteur de dialogue ---
        $response = ""
        if (Get-Command Invoke-AthenaDialogueCore -ErrorAction SilentlyContinue) {
            $response = Invoke-AthenaDialogueCore -InputText $Input
        } else {
            $response = "Je tâ€™Ã©coute, mais mon module DialogueCore nâ€™est pas encore chargÃ©."
        }

        if ([string]::IsNullOrWhiteSpace($response)) {
            $response = "Aucune rÃ©ponse gÃ©nÃ©rÃ©e par le moteur de dialogue."
        }

        $Global:Athena_LastResponse = $response

        # === Affichage + Synchronisation Cockpit ===
        [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        [System.Console]::WriteLine("")
        [System.Console]::WriteLine("ðŸ¤– Athena : {0}" -f $response)
        [System.Console]::WriteLine("")
        Send-ToCockpit -Message $response -Type "Athena"

        # --- Voix + mise Ã  jour ---
        Speak-AthenaResponse $response
        Update-EmotionState "Stable"
        Update-CockpitState -Status "RÃ©ponse gÃ©nÃ©rÃ©e" -LastAction "Dialogue traitÃ©" -Progress 100

        # --- Log ---
        $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Add-Content -Path $Global:Athena_LogPath -Value "[$time] Toi  : $Input"
        Add-Content -Path $Global:Athena_LogPath -Value "[$time] Athena : $response"

        # --- DÃ©clencheur Ã©ventuel ---
        if ($response -match "projet|usine|crÃ©e|construction|workflow") {
            Auto-ProjectTrigger -UserCommand $Input
        }

        return $response
    }
    catch {
        [System.Console]::WriteLine("âŒ Erreur dialogue : {0}" -f $_.Exception.Message)
        Send-ToCockpit -Message ("Erreur dialogue : " + $_.Exception.Message) -Type "Error"
    }
}

Export-ModuleMember -Function Send-ToCockpit -Force


