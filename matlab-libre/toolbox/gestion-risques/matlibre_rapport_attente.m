function statistique = matlibre_rapport_attente(n, p)
%MATLIBRE_RAPPORT_ATTENTE Rapport de vraisemblance d'un temps d'attente.
%   La loi géométrique de paramètre p donne au premier dépassement à la
%   date n la vraisemblance p(1-p)^(n-1) ; la valeur libre est celle du
%   paramètre 1/n, qui rend cette date la plus probable.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if n <= 1
        statistique = -2 * log(p / 1);
        return
    end
    sousNulle = log(p) + (n - 1) * log(1 - p);
    sousLibre = log(1 / n) + (n - 1) * log(1 - 1 / n);
    statistique = -2 * (sousNulle - sousLibre);
end
