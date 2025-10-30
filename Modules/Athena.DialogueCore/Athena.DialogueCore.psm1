function Invoke-AthenaDialogueCore {
    param([string]$InputText)

    if ($InputText -match "prÃªte|pret|pretes") {
        return "Oui Yoann, je suis prÃªte et entiÃ¨rement opÃ©rationnelle."
    }
    elseif ($InputText -match "etat|Ã©tat|status|statut") {
        return "Mon Ã©tat est stable, tous les modules essentiels fonctionnent."
    }
    elseif ($InputText -match "diagnostic") {
        return "Je vais lancer un diagnostic complet des systÃ¨mes."
    }
    elseif ($InputText -match "projet|usine|creation") {
        return "Souhaites-tu que je dÃ©marre un nouveau projet ?"
    }
    else {
        return "Je tâ€™Ã©coute, mais je nâ€™ai pas encore appris Ã  rÃ©pondre Ã  cette phrase."
    }
}

Export-ModuleMember -Function Invoke-AthenaDialogueCore


