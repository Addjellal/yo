function [montants, dates, courus] = matlibre_flux_obligation(ligne, reglement)
%MATLIBRE_FLUX_OBLIGATION Flux d'une obligation décrite par une ligne.
%   LIGNE vaut [echeance tauxCoupon face periode base regleFinMois] ;
%   seules les deux premières colonnes sont obligatoires.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    echeance = ligne(1);
    tauxCoupon = 0;
    if numel(ligne) >= 2, tauxCoupon = ligne(2); end
    valeurFaciale = 100;
    if numel(ligne) >= 3 && ~isnan(ligne(3)), valeurFaciale = ligne(3); end
    periode = 2;
    if numel(ligne) >= 4 && ~isnan(ligne(4)), periode = ligne(4); end
    base = 0;
    if numel(ligne) >= 5 && ~isnan(ligne(5)), base = ligne(5); end
    regleFinMois = 1;
    if numel(ligne) >= 6 && ~isnan(ligne(6)), regleFinMois = ligne(6); end
    [tous, toutesDates] = cfamounts(tauxCoupon, reglement, echeance, periode, ...
                                    base, regleFinMois, [], [], [], [], valeurFaciale);
    courus = -tous(1);
    montants = tous(2:end);
    dates = toutesDates(2:end);
end
