function oui = matlibre_definie_positive(H)
%MATLIBRE_DEFINIE_POSITIVE La matrice est-elle symétrique définie positive ?
%   La factorisation de Cholesky échoue exactement dans le cas contraire ;
%   c'est le test le moins coûteux et le plus sûr.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    oui = false;
    if isempty(H) || size(H, 1) ~= size(H, 2)
        return
    end
    if any(any(~isfinite(H)))
        return
    end
    if max(max(abs(H - H.'))) > 1e-10 * max(1, max(max(abs(H))))
        return
    end
    [~, defaut] = chol(H);
    oui = defaut == 0;
end
