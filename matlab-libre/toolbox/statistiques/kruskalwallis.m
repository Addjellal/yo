function [p, tableau, statistiques] = kruskalwallis(y, groupe, affichage)
%KRUSKALWALLIS Analyse de variance sur les rangs.
%   P = KRUSKALWALLIS(Y,GROUPE) teste l'hypothèse « tous les groupes
%   suivent la même distribution », sur les rangs des observations plutôt
%   que sur leurs valeurs. C'est la réponse non paramétrique à la même
%   question qu'ANOVA1 : elle ne suppose ni normalité ni égalité des
%   variances, et résiste aux valeurs aberrantes.
%
%   P = KRUSKALWALLIS(Y) où Y est une matrice traite chaque colonne comme
%   un groupe.
%
%   La statistique du test vaut
%
%      H = 12/(N(N+1)) * somme(n_i * (R_i - (N+1)/2)^2)
%
%   où R_i est le rang moyen du groupe i ; elle suit approximativement
%   une loi du khi-deux à K-1 degrés de liberté. Elle est corrigée des
%   liens par le facteur usuel.
%
%   [P,TABLEAU] = KRUSKALWALLIS(...) rend le détail : la statistique, les
%   degrés de liberté, les sommes des carrés des rangs.
%   [P,TABLEAU,STATS] = KRUSKALWALLIS(...) rend de quoi appeler
%   MULTCOMPARE.
%
%   Exemples :
%      y = [1 2 3 100 101 102];
%      g = [1 1 1 2 2 2];
%      kruskalwallis(y, g)          % 0.0495 : le maximum possible a 3+3
%      anova1(y, g)                 % beaucoup plus petit, mais suppose
%                                   % la normalite
%
%   Voir aussi ANOVA1, RANKSUM, FRIEDMAN, MULTCOMPARE, TIEDRANK.
    if nargin < 2 || isempty(groupe)
        if isvector(y)
            error('stats:kruskalwallis:NoGrouping', ...
                  'KRUSKALWALLIS needs a grouping variable, or a matrix of columns.');
        end
        colonnes = size(y, 2);
        groupe = repmat(1:colonnes, size(y, 1), 1);
        groupe = groupe(:);
        y = y(:);
    end
    y = y(:);
    [indices, noms] = grp2idx(groupe);
    garde = ~isnan(y) & ~isnan(indices);
    y = y(garde);
    indices = indices(garde);
    n = numel(y);
    k = numel(noms);
    [rangs, correctionLiens] = tiedrank(y);
    rangMoyen = zeros(k, 1);
    effectifs = zeros(k, 1);
    H = 0;
    for i = 1:k
        ri = rangs(indices == i);
        effectifs(i) = numel(ri);
        if effectifs(i) == 0
            continue;
        end
        rangMoyen(i) = mean(ri);
        H = H + effectifs(i) * (rangMoyen(i) - (n + 1) / 2) ^ 2;
    end
    H = 12 / (n * (n + 1)) * H;
    % Correction des liens : sans elle, H est sous-estimé.
    correction = 1 - 2 * correctionLiens / (n ^ 3 - n);
    if correction > 0
        H = H / correction;
    end
    ddl = k - 1;
    p = 1 - chi2cdf(H, ddl);
    sceInter = 0;
    for i = 1:k
        sceInter = sceInter + effectifs(i) * (rangMoyen(i) - (n + 1) / 2) ^ 2;
    end
    sceTotal = sum((rangs - (n + 1) / 2) .^ 2);
    tableau = struct('SSB', sceInter, 'SST', sceTotal, 'df', ddl, ...
                     'chisq', H, 'p', p);
    statistiques = struct('gnames', {noms}, 'n', effectifs, ...
                          'source', 'kruskalwallis', 'meanranks', rangMoyen, ...
                          'sumt', 2 * correctionLiens, 'df', n - k);
    if nargin >= 3 && ~isempty(affichage) && strcmpi(char(affichage), 'on')
        boxplot(y, indices);
        title(sprintf('Kruskal-Wallis : H = %.4g, p = %.4g', H, p));
    end
end
