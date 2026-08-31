function [moyennes, ecarts, effectifs, noms] = grpstats(x, groupe, mode)
%GRPSTATS Statistiques par groupe.
%   M = GRPSTATS(X,GROUPE) rend la moyenne de X pour chaque groupe. X est
%   un vecteur colonne, ou une matrice dont chaque ligne est une
%   observation ; GROUPE dit à quel groupe appartient chaque ligne, sous
%   la forme qu'accepte GRP2IDX — nombres ou noms.
%
%   Le résultat a une ligne par groupe, dans l'ordre que rend GRP2IDX.
%
%   [M,S] = GRPSTATS(X,GROUPE) rend aussi l'écart type de chaque groupe.
%   [M,S,N] = GRPSTATS(...) rend le nombre d'observations par groupe.
%   [M,S,N,NOMS] = GRPSTATS(...) rend les noms des groupes.
%
%   GRPSTATS(X,GROUPE,ALPHA) où ALPHA est un nombre entre 0 et 1 dessine
%   les moyennes et leur intervalle de confiance à 100*(1-ALPHA) pour
%   cent, au lieu de rendre des valeurs.
%
%   Sans GROUPE, ou avec un GROUPE vide, tout est traité comme un seul
%   groupe.
%
%   Exemples :
%      x = [1 2 3 10 11 12]';
%      g = {'a','a','a','b','b','b'};
%      [m, s, n] = grpstats(x, g)
%      % m = [2; 11], s = [1; 1], n = [3; 3]
%
%   Voir aussi GRP2IDX, ANOVA1, ACCUMARRAY, SPLITAPPLY, TABULATE.
    if nargin < 2 || isempty(groupe)
        groupe = ones(size(x, 1), 1);
    end
    if isvector(x)
        x = x(:);
    end
    [indices, noms] = grp2idx(groupe);
    if numel(indices) ~= size(x, 1)
        error('stats:grpstats:InputSizeMismatch', ...
              'X and the grouping variable must have the same number of rows.');
    end
    k = numel(noms);
    p = size(x, 2);
    moyennes = NaN(k, p);
    ecarts = NaN(k, p);
    effectifs = zeros(k, 1);
    for g = 1:k
        lignes = indices == g;
        effectifs(g) = sum(lignes);
        if effectifs(g) == 0
            continue;
        end
        bloc = x(lignes, :);
        moyennes(g, :) = mean(bloc, 1);
        if effectifs(g) > 1
            ecarts(g, :) = std(bloc, 0, 1);
        else
            ecarts(g, :) = 0;
        end
    end
    if nargin >= 3 && ~isempty(mode) && isnumeric(mode)
        alpha = mode;
        marge = zeros(k, 1);
        for g = 1:k
            if effectifs(g) > 1
                marge(g) = tinv(1 - alpha / 2, effectifs(g) - 1) * ...
                           ecarts(g, 1) / sqrt(effectifs(g));
            end
        end
        errorbar(1:k, moyennes(:, 1), marge, 'o');
        xlim([0.5, k + 0.5]);
        xticks(1:k);
        xticklabels(noms);
        ylabel('moyenne');
        title(sprintf('Moyennes et intervalles a %g %%', 100 * (1 - alpha)));
        clear moyennes;
        return;
    end
end
