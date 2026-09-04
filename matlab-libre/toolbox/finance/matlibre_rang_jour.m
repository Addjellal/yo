function rang = matlibre_rang_jour(mois, jour)
%MATLIBRE_RANG_JOUR Rang du jour dans une année non bissextile.
%   Le 29 février n'existe pas dans ce calendrier : il est ramené au 28.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    cumul = [0 31 59 90 120 151 181 212 243 273 304 334];
    longueurs = [31 28 31 30 31 30 31 31 30 31 30 31];
    mois = max(min(round(mois), 12), 1);
    jour = min(jour, longueurs(mois));
    rang = cumul(mois) + jour;
end
