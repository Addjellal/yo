function jours = matlibre_jours_ouvres(d1, d2, feries)
%MATLIBRE_JOURS_OUVRES Jours ouvrés d'un intervalle, borne de gauche exclue.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 3
        feries = [];
    end
    if d2 <= d1
        jours = [];
        return
    end
    candidats = (floor(d1) + 1):floor(d2);
    jours = candidats(isbusday(candidats, feries));
end
