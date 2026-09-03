function [a, b] = matlibre_gf_etendre(a, b)
%MATLIBRE_GF_ETENDRE Répand un scalaire sur la taille de l'autre tableau.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isequal(size(a), size(b))
        return
    end
    if numel(a) == 1
        a = repmat(a, size(b));
    elseif numel(b) == 1
        b = repmat(b, size(a));
    else
        error('comm:gf:Tailles', ...
              'Les deux tableaux doivent avoir la même taille.');
    end
end
