function taux = matlibre_escompte_vers_taux(facteurs, annees, composition)
%MATLIBRE_ESCOMPTE_VERS_TAUX Taux zéro-coupon d'une suite de facteurs.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    facteurs = facteurs(:);
    annees = annees(:);
    if composition == -1
        taux = -log(facteurs) ./ annees;
    elseif composition == 0
        taux = (1 ./ facteurs - 1) ./ annees;
    else
        taux = composition * (facteurs .^ (-1 ./ (composition * annees)) - 1);
    end
end
