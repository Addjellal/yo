function [dates, durees, facteurs] = matlibre_cds_echeancier(courbe, reglement, echeance, frequence, base)
%MATLIBRE_CDS_ECHEANCIER Dates de prime d'un contrat de protection.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    reglement = matlibre_dates(reglement);
    echeance = matlibre_dates(echeance);
    dates = matlibre_echeancier(reglement, echeance, frequence, 1).';
    precedentes = [reglement; dates(1:end-1).'];
    durees = zeros(numel(dates), 1);
    for k = 1:numel(dates)
        durees(k) = yearfrac(precedentes(k), dates(k), base);
    end
    facteurs = matlibre_courbe_escompte(courbe, dates);
    facteurs = facteurs(:);
end
