function ecart = matlibre_cds_ecart(courbe, reglement, echeance, hasard, datesHasard, recuperation, frequence, base)
%MATLIBRE_CDS_ECART Écart d'équilibre d'un contrat de protection.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    [annuite, protection] = matlibre_cds_branches(courbe, reglement, echeance, ...
        hasard, datesHasard, recuperation, frequence, base);
    if annuite <= 0
        ecart = 0;
    else
        ecart = protection / annuite;
    end
end
