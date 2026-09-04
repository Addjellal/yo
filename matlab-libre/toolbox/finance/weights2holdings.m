function quantites = weights2holdings(poids, prix, valeur)
%WEIGHTS2HOLDINGS Quantités à détenir pour atteindre des poids donnés.
%   Q = WEIGHTS2HOLDINGS(POIDS,PRIX,VALEUR) rend le nombre de titres à
%   acheter de chacun pour placer VALEUR selon les poids donnés.
%
%   Exemple :
%      weights2holdings([0.5 0.5], [10 5], 2000)    % [100 200]
%
%   Voir aussi HOLDINGS2WEIGHTS, PORTSTATS.
    poids = double(poids);
    prix = double(prix(:)).';
    if nargin < 3 || isempty(valeur)
        valeur = 1;
    end
    valeur = double(valeur(:));
    if isscalar(valeur)
        valeur = repmat(valeur, size(poids, 1), 1);
    end
    quantites = poids .* repmat(valeur, 1, size(poids, 2)) ./ ...
                repmat(prix, size(poids, 1), 1);
end
