function [correlations, decalages] = modwtxcorr(w1, w2, nom, decalageMax)
%MODWTXCORR Corrélation croisée par échelle entre deux signaux.
%   C = MODWTXCORR(W1,W2) rend, dans une cellule, la corrélation croisée
%   normalisée de chaque échelle : C{K} porte les valeurs pour tous les
%   décalages. Le maximum dit de combien la seconde série est en retard
%   sur la première, à cette échelle-là.
%
%   [C,DECALAGES] = MODWTXCORR(...) rend aussi le vecteur des décalages.
%   MODWTXCORR(W1,W2,NOM,MAXDEC) borne le décalage.
%
%   Exemple :
%      x = cumsum(randn(1, 512));
%      y = circshift(x, 8);
%      [c, d] = modwtxcorr(modwt(x, 'db2', 3), modwt(y, 'db2', 3));
%      [~, i] = max(c{3});
%      d(i)                           % environ 8
%
%   Voir aussi MODWTCORR, MODWTVAR, XCORR, MODWT.
    if nargin < 3, nom = ''; end %#ok<INUSA>
    if ~isequal(size(w1), size(w2))
        error('wavelet:modwtxcorr:Tailles', ...
              'Les deux transformées doivent avoir la même taille.');
    end
    [lignes, n] = size(w1);
    if nargin < 4 || isempty(decalageMax)
        decalageMax = n - 1;
    end
    decalageMax = min(round(decalageMax), n - 1);
    decalages = -decalageMax:decalageMax;
    correlations = cell(lignes, 1);
    for k = 1:lignes
        a = w1(k, :);
        b = w2(k, :);
        normalisation = sqrt(sum(a .^ 2) * sum(b .^ 2));
        valeurs = zeros(1, numel(decalages));
        for j = 1:numel(decalages)
            d = decalages(j);
            % Corrélation circulaire : la MODWT est déjà circulaire, et
            % l'on garde ainsi tous les termes à chaque décalage.
            valeurs(j) = sum(a .* circshift(b, [0, d]));
        end
        if normalisation > 0
            valeurs = valeurs / normalisation;
        end
        correlations{k} = valeurs;
    end
end
