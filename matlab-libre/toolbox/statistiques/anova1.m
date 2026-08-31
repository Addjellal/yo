function [p, tableau, statistiques] = anova1(y, groupe, affichage)
%ANOVA1 Analyse de variance à un facteur.
%   P = ANOVA1(Y,GROUPE) teste l'hypothèse « tous les groupes ont la même
%   moyenne ». Y est un vecteur d'observations, GROUPE dit à quel groupe
%   appartient chacune — sous la forme qu'accepte GRP2IDX : des nombres,
%   des noms, un tableau de cellules.
%
%   P = ANOVA1(Y) où Y est une matrice traite chaque colonne comme un
%   groupe. C'est la forme la plus courte quand les groupes ont tous le
%   même effectif.
%
%   P est la probabilité critique : la chance d'observer un écart entre
%   moyennes au moins aussi grand si toutes étaient égales. Une petite
%   valeur conduit à rejeter cette égalité.
%
%   [P,TABLEAU] = ANOVA1(...) rend en outre le tableau de l'analyse, sous
%   la forme d'une structure :
%      SSB, dfB    somme des carrés et degrés de liberté intergroupes ;
%      SSW, dfW    idem intragroupes ;
%      MSB, MSW    les carrés moyens, quotients des précédents ;
%      F           leur rapport, la statistique du test ;
%      p           la probabilité critique.
%
%   [P,TABLEAU,STATS] = ANOVA1(...) rend de quoi comparer les groupes
%   deux à deux par MULTCOMPARE : leurs moyennes, leurs effectifs, leurs
%   noms et le degré de liberté résiduel.
%
%   Le test suppose des groupes normaux et de même variance. Quand la
%   normalité est douteuse, KRUSKALWALLIS répond à la même question sur
%   les rangs.
%
%   Exemples :
%      y = [5 6 7 10 11 12];
%      g = [1 1 1 2 2 2];
%      anova1(y, g)                     % petit : les moyennes different
%
%      anova1([1 2; 2 3; 3 4])          % deux colonnes, deux groupes
%
%      [p, t, s] = anova1(y, g);
%      t.F                              % la statistique de Fisher
%
%   Voir aussi ANOVA2, KRUSKALWALLIS, MULTCOMPARE, TTEST2, GRPSTATS.
    if nargin < 2 || isempty(groupe)
        if isvector(y)
            error('stats:anova1:NoGrouping', ...
                  'ANOVA1 needs a grouping variable, or a matrix of columns.');
        end
        % Une matrice : une colonne par groupe.
        colonnes = size(y, 2);
        valeurs = y(:);
        groupe = repmat(1:colonnes, size(y, 1), 1);
        groupe = groupe(:);
        y = valeurs;
    end
    y = y(:);
    [indices, noms] = grp2idx(groupe);
    if numel(indices) ~= numel(y)
        error('stats:anova1:InputSizeMismatch', ...
              'Y and the grouping variable must have the same length.');
    end
    garde = ~isnan(y) & ~isnan(indices);
    y = y(garde);
    indices = indices(garde);
    k = numel(noms);
    n = numel(y);
    moyenneGenerale = mean(y);
    sceInter = 0;
    sceIntra = 0;
    moyennes = zeros(k, 1);
    effectifs = zeros(k, 1);
    for i = 1:k
        yi = y(indices == i);
        effectifs(i) = numel(yi);
        if effectifs(i) == 0
            continue;
        end
        moyennes(i) = mean(yi);
        sceInter = sceInter + effectifs(i) * (moyennes(i) - moyenneGenerale) ^ 2;
        sceIntra = sceIntra + sum((yi - moyennes(i)) .^ 2);
    end
    ddlInter = k - 1;
    ddlIntra = n - k;
    if ddlIntra <= 0 || sceIntra == 0
        F = Inf;
        p = 0;
    else
        F = (sceInter / ddlInter) / (sceIntra / ddlIntra);
        p = 1 - fcdf(F, ddlInter, ddlIntra);
    end
    tableau = struct('SSB', sceInter, 'SSW', sceIntra, 'dfB', ddlInter, ...
                     'dfW', ddlIntra, 'MSB', sceInter / max(ddlInter, 1), ...
                     'MSW', sceIntra / max(ddlIntra, 1), 'F', F, 'p', p);
    statistiques = struct('gnames', {noms}, 'n', effectifs, 'source', 'anova1', ...
                          'means', moyennes, 'df', ddlIntra, ...
                          's', sqrt(sceIntra / max(ddlIntra, 1)));
    if nargin >= 3 && ~isempty(affichage) && ...
       (strcmpi(char(affichage), 'on') || strcmpi(char(affichage), 'boxplot'))
        boxplot(y, indices);
        title(sprintf('ANOVA a un facteur : F = %.4g, p = %.4g', F, p));
    end
end
