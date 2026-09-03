function x = idwt(approximation, detail, nom, longueur)
%IDWT Reconstruction à partir de l'approximation et du détail.
%   X = IDWT(A,D,NOM) inverse DWT. L'extension étant périodique,
%   l'inverse redistribue chaque coefficient sur les positions que
%   l'analyse avait lues, cette fois avec les filtres de synthèse.
%
%   X = IDWT(A,D,NOM,L) ne garde que les L premiers échantillons : c'est
%   ce qu'il faut quand le signal analysé était de longueur impaire, DWT
%   l'ayant alors prolongé d'un point.
%
%   Exemple :
%      [a, d] = dwt(1:8, 'db2');
%      max(abs(idwt(a, d, 'db2') - (1:8)))   % nul à l'arrondi près
%
%   Voir aussi DWT, WAVEREC, WFILTERS.
    if nargin < 3 || isempty(nom)
        nom = 'haar';
    end
    [Lo_R, Hi_R] = wfilters(nom, 'r');
    m = numel(approximation);
    n = 2 * m;
    f = numel(Lo_R);
    x = zeros(1, n);
    for k = 1:m
        for j = 1:f
            indice = mod(2 * k - 2 + j - 1, n) + 1;
            x(indice) = x(indice) + Lo_R(j) * approximation(k) + Hi_R(j) * detail(k);
        end
    end
    if nargin >= 4 && ~isempty(longueur)
        longueur = round(longueur);
        if longueur > n
            error('wavelet:idwt:Longueur', ...
                  'La longueur demandée dépasse celle que rendent les coefficients.');
        end
        x = x(1:longueur);
    end
end
