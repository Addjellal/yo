function [r, nombreLiens] = tiedrank(x)
%TIEDRANK Rangs, les valeurs égales recevant leur rang moyen.
%   R = TIEDRANK(X) rend le rang de chaque élément de X. Le plus petit
%   reçoit le rang 1. Quand plusieurs valeurs sont égales, chacune reçoit
%   la moyenne des rangs qu'elles auraient occupés : deux valeurs égales
%   aux places 3 et 4 reçoivent toutes deux 3.5.
%
%   C'est ce dont les tests de rangs ont besoin — RANKSUM, SIGNRANK, la
%   corrélation de Spearman — pour que les liens ne faussent pas la
%   statistique.
%
%   [R,N] = TIEDRANK(X) rend en outre un terme de correction des liens,
%   somme des (t^3 - t) sur les groupes de t valeurs égales, divisée par
%   deux. Il vaut 0 s'il n'y a aucun lien.
%
%   Pour une matrice, chaque colonne est classée séparément.
%
%   Les NaN reçoivent le rang NaN et ne comptent pas dans le classement.
%
%   Exemples :
%      tiedrank([10 20 20 40])           % [1 2.5 2.5 4]
%      tiedrank([3 1 2])                 % [3 1 2]
%      [r, n] = tiedrank([1 1 1])        % r = [2 2 2], n = 12
%
%   Voir aussi SORT, RANKSUM, SIGNRANK, CORR.
    if ~isvector(x)
        r = zeros(size(x));
        nombreLiens = zeros(1, size(x, 2));
        for j = 1:size(x, 2)
            [r(:, j), nombreLiens(j)] = tiedrank(x(:, j));
        end
        return;
    end
    forme = size(x);
    v = x(:);
    n = numel(v);
    present = ~isnan(v);
    r = NaN(n, 1);
    idx = find(present);
    [tries, ordre] = sort(v(idx));
    rangs = zeros(numel(tries), 1);
    nombreLiens = 0;
    k = 1;
    while k <= numel(tries)
        j = k;
        while j < numel(tries) && tries(j + 1) == tries(k)
            j = j + 1;
        end
        rangs(k:j) = (k + j) / 2;
        t = j - k + 1;
        if t > 1
            nombreLiens = nombreLiens + (t ^ 3 - t) / 2;
        end
        k = j + 1;
    end
    r(idx(ordre)) = rangs;
    r = reshape(r, forme);
end
