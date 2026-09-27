function f = matlibre_fixe_precision(v, signe, w, F)
%MATLIBRE_FIXE_PRECISION Le plus de bits après la virgule qui tiennent.
%   F = MATLIBRE_FIXE_PRECISION(V,SIGNE,W) rend le nombre de bits après la
%   virgule le plus grand pour lequel toutes les valeurs de V, arrondies
%   au plus proche, tiennent sur W bits, signés ou non : la meilleure
%   précision, que prend FI quand l'échelle n'est pas donnée. Des zéros
%   seuls en laissent W - 1 (W sans signe).
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi FI.
    if nargin < 4
        F = struct('RoundingMethod', 'Nearest');
    end
    v = double(v(:));
    v = v(isfinite(v));
    if ~signe
        v = v(v > 0);   % sans signe, un négatif sature à zéro : il ne compte pas
    end
    m = max(abs(v));
    if isempty(m) || m == 0
        f = w - signe;
        return
    end
    haut = 2 ^ (w - signe) - 1;
    bas = -signe * 2 ^ (w - 1);
    f = w - signe - floor(log2(m)) - 1;
    % au plus près : la formule, puis un pas de chaque côté selon l'arrondi
    while tient(v, f + 1, bas, haut, F)
        f = f + 1;
    end
    while ~tient(v, f, bas, haut, F) && f > -65535
        f = f - 1;
    end
end

function oui = tient(v, f, bas, haut, F)
    q = matlibre_fixe_arrondir(v * 2 ^ f, F.RoundingMethod);
    oui = all(q >= bas & q <= haut);
end
