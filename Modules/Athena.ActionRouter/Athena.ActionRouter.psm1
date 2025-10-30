# ====================================================================
# ðŸ§  Athena.ActionRouter.psm1
# Version : v1.0-FusionCore
# Auteur  : Yoann Rousselle / Athena Core
# RÃ´le   : ReÃ§oit les ordres structurÃ©s (via MCP ou JSON) et dÃ©clenche les modules liÃ©s
# ====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

function Invoke-AthenaAction {
    param(
        [Parameter(Mandatory)][string]$Action,
        [string]$Param
    )

    Write-Host "ðŸ§­ Action demandÃ©e : $Action ($Param)" -ForegroundColor Cyan

    switch ($Action.ToLower()) {
        'build_project' {
            if (-not (Get-Module -Name Athena.Toolbox -ErrorAction SilentlyContinue)) {
                Import-Module "$PSScriptRoot\..\Modules\Athena.Toolbox.psm1" -Force
            }
            return Invoke-AthenaProjectCreation -Name $Param
        }

        'self_update' {
            Import-Module "$PSScriptRoot\..\Modules\Athena.AutoPatch.psm1" -Force
            return Invoke-AthenaAutoPatch
        }

        'self_repair' {
            Import-Module "$PSScriptRoot\..\Modules\Athena.SelfRepair.psm1" -Force
            return Invoke-AthenaSelfRepair
        }

        default {
            return "â“ Action inconnue : $Action"
        }
    }
}

Export-ModuleMember -Function Invoke-AthenaAction


