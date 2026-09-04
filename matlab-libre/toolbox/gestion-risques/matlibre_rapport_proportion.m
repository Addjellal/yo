function statistique = matlibre_rapport_proportion(x, N, p)
%MATLIBRE_RAPPORT_PROPORTION Rapport de vraisemblance de Kupiec.
%   Compare la vraisemblance sous la proportion annoncée à celle sous la
%   proportion observée. Elle est nulle quand les deux coïncident, et
%   croît de part et d'autre.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if x == 0
        statistique = -2 * (N * log(1 - p));
        return
    end
    if x == N
        statistique = -2 * (N * log(p));
        return
    end
    observee = x / N;
    sousNulle = (N - x) * log(1 - p) + x * log(p);
    sousLibre = (N - x) * log(1 - observee) + x * log(observee);
    statistique = -2 * (sousNulle - sousLibre);
end
