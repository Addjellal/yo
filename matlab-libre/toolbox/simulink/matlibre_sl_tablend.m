function y = matlibre_sl_tablend(T, B, U, methode, extrapolation)
%MATLIBRE_SL_TABLEND Interpole dans une table à N dimensions.
%   Y = MATLIBRE_SL_TABLEND(T,B,U,METHODE,EXTRAPOLATION) rend, pour chaque
%   élément des entrées, la valeur de la table T — un tableau à N
%   dimensions, de taille numel(B{1}) x ... x numel(B{N}) — au point
%   U{1}(k), ..., U{N}(k). B{D} porte les points de la dimension D, en
%   ordre croissant. Une entrée scalaire vaut pour tous les éléments.
%
%   METHODE : 'Linear point-slope' ou 'Linear' (multilinéaire), 'Flat'
%   (la valeur au point de rupture inférieur) ou 'Nearest' (au plus
%   proche). EXTRAPOLATION : 'Clip' (les entrées sont ramenées dans les
%   bornes) ou 'Linear' (prolongée par le premier ou le dernier
%   intervalle).
%
%   C'est ce que calcule le bloc n-D Lookup Table au-delà de deux
%   dimensions.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      T = reshape(1:8, [2 2 2]);
%      matlibre_sl_tablend(T, {[0 1], [0 1], [0 1]}, {0.5, 0, 1}, 'Linear', 'Clip')  % 5.5
%
%   Voir aussi INTERPN, ADD_BLOCK.
    n = numel(B);
    largeur = max(cellfun(@numel, U));
    y = zeros(largeur, 1);
    tailles = size(T);
    tailles(end + 1:n) = 1;
    for e = 1:largeur
        rang = zeros(1, n);
        part = zeros(1, n);
        for d = 1:n
            b = double(B{d}(:));
            x = double(U{d}(min(e, numel(U{d}))));
            m = numel(b);
            if m == 1
                rang(d) = 1;
                part(d) = 0;
                continue
            end
            if strcmp(extrapolation, 'Clip')
                x = min(max(x, b(1)), b(end));
            end
            i = find(b <= x, 1, 'last');
            if isempty(i)
                i = 1;
            end
            i = min(i, m - 1);
            f = (x - b(i)) / (b(i + 1) - b(i));
            switch methode
                case 'Flat'
                    f = double(f >= 1);
                case 'Nearest'
                    f = double(f >= 0.5);
            end
            rang(d) = i;
            part(d) = f;
        end
        somme = 0;
        for coin = 0:2^n - 1
            bits = bitget(coin, 1:n);
            poids = prod(bits .* part + (1 - bits) .* (1 - part));
            if poids == 0
                continue
            end
            indices = num2cell(min(rang + bits, tailles(1:n)));
            somme = somme + poids * T(sub2ind(tailles(1:n), indices{:}));
        end
        y(e) = somme;
    end
end
