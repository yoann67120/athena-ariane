# Chemin vers le rÃ©pertoire des modules Ariane
$modulePath = "C:\Chemin\Vers\Modules\Ariane"

# Liste des fichiers de module avec leurs sommes de contrÃ´le de rÃ©fÃ©rence
$referenceHashes = @{
    "Module1.psm1" = "hash_de_reference_1"
    "Module2.psm1" = "hash_de_reference_2"
    # Ajoutez d'autres modules et leurs hash de rÃ©fÃ©rence ici
}

# Fonction pour calculer le hash d'un fichier
function Get-FileHashValue {
    param (
        [string]$filePath
    )
    return Get-FileHash -Path $filePath -Algorithm SHA256 | Select-Object -ExpandProperty Hash
}

# VÃ©rification de l'intÃ©gritÃ© des modules
foreach ($module in Get-ChildItem -Path $modulePath -Filter *.psm1) {
    $fileName = $module.Name
    if ($referenceHashes.ContainsKey($fileName)) {
        $currentHash = Get-FileHashValue -filePath $module.FullName
        $referenceHash = $referenceHashes[$fileName]

        if ($currentHash -eq $referenceHash) {
            Write-Host "$fileName est intÃ¨gre." -ForegroundColor Green
        } else {
            Write-Host "$fileName a Ã©tÃ© modifiÃ©." -ForegroundColor Red
        }
    } else {
        Write-Host "Aucune somme de contrÃ´le de rÃ©fÃ©rence pour $fileName." -ForegroundColor Yellow
    }
}
Export-ModuleMember -Function *

