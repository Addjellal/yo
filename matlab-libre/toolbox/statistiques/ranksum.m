function [p, h, statistiques] = ranksum(x, y, alpha)
%RANKSUM Test de Wilcoxon-Mann-Whitney sur deux échantillons.
%   P = RANKSUM(X,Y) rend la p-valeur bilatérale de l'hypothèse « les deux
%   échantillons viennent de la même loi ». L'approximation normale est
%   utilisée, avec correction de continuité.
%
%   Exemple :
%      ranksum(1:10, 11:20)   % très petite : les deux groupes diffèrent
    if nargin < 3, alpha = 0.05; end
    x = x(:);
    y = y(:);
    nx = numel(x);
    ny = numel(y);
    ensemble = [x; y];
    [~, ordre] = sort(ensemble);
    rangs = zeros(size(ensemble));
    rangs(ordre) = 1:numel(ensemble);
    % Rangs moyens en cas d'ex aequo.
    valeursTriees = ensemble(ordre);
    k = 1;
    while k <= numel(valeursTriees)
        j = k;
        while j < numel(valeursTriees) && valeursTriees(j + 1) == valeursTriees(k)
            j = j + 1;
        end
        if j > k
            rangs(ordre(k:j)) = mean(k:j);
        end
        k = j + 1;
    end
    W = sum(rangs(1:nx));
    moyenne = nx * (nx + ny + 1) / 2;
    variance = nx * ny * (nx + ny + 1) / 12;
    z = (W - moyenne - 0.5 * sign(W - moyenne)) / sqrt(variance);
    p = 2 * (1 - normcdf(abs(z)));
    h = p < alpha;
    statistiques = struct('ranksum', W, 'zval', z);
end
