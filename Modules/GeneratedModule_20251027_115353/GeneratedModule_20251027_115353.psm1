# Chemin vers le rÃ©pertoire des modules Ariane
$modulePath = "C:\Chemin\Vers\Modules\Ariane"

# Fichier contenant les sommes de contrÃ´le de rÃ©fÃ©rence
$hashFile = "C:\Chemin\Vers\Fichier\de\RÃ©fÃ©rence\hashes.txt"

# Fonction pour calculer la somme de contrÃ´le d'un fichier
function Get-FileHash {
    param (
        [string]$filePath
    )
    if (Test-Path $filePath) {
        return Get-FileHash -Path $filePath -Algorithm SHA256
    } else {
        Write-Host "Fichier non trouvÃ© : $filePath"
        return $null
    }
}

# Lire les sommes de contrÃ´le de rÃ©fÃ©rence
$referenceHashes = Get-Content $hashFile | ConvertFrom-StringData

# VÃ©rifier l'intÃ©gritÃ© des fichiers
foreach ($file in Get-ChildItem -Path $modulePath -File) {
    $fileHash = Get-FileHash -filePath $file.FullName
    if ($fileHash) {
        $fileName = $file.Name
        if ($referenceHashes.ContainsKey($fileName)) {
            if ($fileHash.Hash -eq $referenceHashes[$fileName]) {
                Write-Host "IntÃ©gritÃ© vÃ©rifiÃ©e pour : $fileName"
            } else {
                Write-Host "Alerte : IntÃ©gritÃ© compromise pour : $fileName"
            }
        } else {
            Write-Host "Alerte : Pas de somme de contrÃ´le de rÃ©fÃ©rence pour : $fileName"
        }
    }
}
Export-ModuleMember -Function *

