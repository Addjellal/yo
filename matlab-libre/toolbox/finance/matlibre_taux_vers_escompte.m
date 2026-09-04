function facteurs = matlibre_taux_vers_escompte(taux, annees, composition)
%MATLIBRE_TAUX_VERS_ESCOMPTE Facteurs d'actualisation d'une courbe de taux.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    facteurs = matlibre_escompte(taux(:), annees(:), composition);
end
