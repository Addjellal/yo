function [p, tableau, statistiques] = friedman(y, repetitions)
%FRIEDMAN Analyse de variance sur les rangs, par blocs.
%   P = FRIEDMAN(Y,REPS) teste l'hypothèse « les colonnes de Y ont le
%   même effet », en classant les observations à l'intérieur de chaque
%   bloc — chaque ligne, ou chaque groupe de REPS lignes. C'est le
%   pendant non paramétrique d'ANOVA2 sans interaction : le classement
%   par bloc élimine l'effet des lignes sans avoir à le modéliser.
%
%   REPS vaut 1 par défaut : une observation par case.
%
%   La statistique vaut
%
%      Q = 12/(b*k*(k+1)) * somme(R_j^2) - 3*b*(k+1)
%
%   où b est le nombre de blocs, k celui des colonnes, R_j la somme des
%   rangs de la colonne j ; elle suit une loi du khi-deux à k-1 degrés de
%   liberté.
%
%   [P,TABLEAU] = FRIEDMAN(...) rend le détail du calcul.
%   [P,TABLEAU,STATS] = FRIEDMAN(...) rend de quoi appeler MULTCOMPARE.
%
%   Exemples :
%      % Quatre juges (lignes), trois vins (colonnes)
%      y = [3 5 8; 2 6 9; 4 5 7; 3 6 8];
%      friedman(y)                  % petit : les vins different
%
%   Voir aussi ANOVA2, KRUSKALWALLIS, SIGNRANK, MULTCOMPARE.
    if nargin < 2 || isempty(repetitions)
        repetitions = 1;
    end
    [lignes, k] = size(y);
    if mod(lignes, repetitions) ~= 0
        error('stats:friedman:BadReps', ...
              'The number of rows must be a multiple of REPS.');
    end
    b = lignes / repetitions;
    % Les rangs à l'intérieur de chaque bloc, toutes répétitions confondues.
    rangs = zeros(lignes, k);
    for i = 1:b
        premieres = (i - 1) * repetitions + 1;
        dernieres = i * repetitions;
        bloc = y(premieres:dernieres, :);
        r = tiedrank(bloc(:));
        rangs(premieres:dernieres, :) = reshape(r, repetitions, k);
    end
    sommeColonne = sum(rangs, 1);
    n = repetitions * b;                 % observations par colonne
    rangMoyenGeneral = (n * k + 1) / 2;
    sceColonnes = n * sum((sommeColonne / n - rangMoyenGeneral) .^ 2);
    sceTotal = sum((rangs(:) - rangMoyenGeneral) .^ 2);
    ddl = k - 1;
    ddlErreur = (n - 1) * (k - 1);
    sceErreur = sceTotal - sceColonnes;
    % La forme du khi-deux, celle qui ne dépend que des sommes de rangs.
    Q = sceColonnes / (sceTotal / (b * (repetitions * k - 1)));
    p = 1 - chi2cdf(Q, ddl);
    tableau = struct('SSC', sceColonnes, 'SSE', sceErreur, 'SST', sceTotal, ...
                     'df', ddl, 'dfE', ddlErreur, 'chisq', Q, 'p', p);
    noms = cell(k, 1);
    for j = 1:k
        noms{j} = num2str(j);
    end
    statistiques = struct('gnames', {noms}, 'n', repmat(n, k, 1), ...
                          'source', 'friedman', 'meanranks', (sommeColonne / n)', ...
                          'sigma', sqrt(k * (k + 1) / (6 * b)), 'df', ddlErreur);
end
