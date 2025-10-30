# Plan de Nettoyage PowerShell

# Ã‰tape 1 : CrÃ©er la structure de dossiers
New-Item -Path "C:\AuditArianeV4" -ItemType Directory
New-Item -Path "C:\AuditArianeV4\Modules" -ItemType Directory
New-Item -Path "C:\AuditArianeV4\Scripts" -ItemType Directory
New-Item -Path "C:\AuditArianeV4\Logs" -ItemType Directory
New-Item -Path "C:\AuditArianeV4\Archives" -ItemType Directory

# Ã‰tape 2 : DÃ©placer les fichiers dans les dossiers appropriÃ©s
# Garder les modules car ils sont essentiels pour le fonctionnement
Move-Item -Path "C:\SourcePath\Modules\*" -Destination "C:\AuditArianeV4\Modules"

# Garder les scripts car ils peuvent Ãªtre nÃ©cessaires pour des tÃ¢ches spÃ©cifiques
Move-Item -Path "C:\SourcePath\Scripts\*" -Destination "C:\AuditArianeV4\Scripts"

# Archiver les logs car ils peuvent Ãªtre utiles pour des audits futurs
Move-Item -Path "C:\SourcePath\Logs\*" -Destination "C:\AuditArianeV4\Archives"

# Ã‰tape 3 : Supprimer les fichiers inutiles
# Supposons qu'il y a des fichiers temporaires ou obsolÃ¨tes Ã  supprimer
Remove-Item -Path "C:\SourcePath\Temp\*" -Recurse -Force

# Ã‰tape 4 : Fusionner les fichiers si nÃ©cessaire
# Exemple : Fusionner les fichiers de configuration s'il y en a
# (Aucun fichier de configuration dans cet audit, donc cette Ã©tape est omise)

# Structure finale des dossiers :
# C:\AuditArianeV4\
# â”œâ”€â”€ Modules\
# â”œâ”€â”€ Scripts\
# â”œâ”€â”€ Logs\
# â””â”€â”€ Archives\

# Le plan de nettoyage est maintenant en place.
Export-ModuleMember -Function *

