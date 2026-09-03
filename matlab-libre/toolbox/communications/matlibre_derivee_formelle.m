function d = matlibre_derivee_formelle(poly)
%MATLIBRE_DERIVEE_FORMELLE Dérivée d'un polynôme de caractéristique deux.
%   Les coefficients vont par puissances croissantes. Dans un corps de
%   caractéristique deux, dériver garde un terme sur deux : les termes de
%   degré pair disparaissent, deux fois quoi que ce soit valant zéro.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    poly = double(poly(:)).';
    n = numel(poly);
    if n <= 1
        d = 0;
        return
    end
    d = zeros(1, n - 1);
    for k = 2:n
        if mod(k - 1, 2) == 1
            d(k - 1) = poly(k);
        end
    end
end
