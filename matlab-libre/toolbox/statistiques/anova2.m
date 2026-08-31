function [p, tableau] = anova2(y, repetitions)
%ANOVA2 Analyse de variance à deux facteurs, plan équilibré.
%   P = ANOVA2(Y,REPS) teste trois hypothèses à la fois sur un tableau Y
%   dont les colonnes sont les niveaux d'un facteur et les lignes ceux
%   d'un autre. REPS dit combien de lignes consécutives de Y sont des
%   répétitions du même couple de niveaux ; il vaut 1 quand il n'y en a
%   qu'une par case.
%
%   P est un vecteur de deux ou trois probabilités critiques :
%      P(1)  l'effet des colonnes ;
%      P(2)  l'effet des lignes ;
%      P(3)  leur interaction, quand REPS est supérieur à 1.
%
%   [P,TABLEAU] = ANOVA2(...) rend le détail sous la forme d'une
%   structure : sommes des carrés, degrés de liberté, carrés moyens et
%   statistiques de Fisher pour les colonnes, les lignes, l'interaction
%   et l'erreur.
%
%   Le plan doit être équilibré : autant d'observations dans chaque case.
%   C'est ce qui permet d'écrire les sommes des carrés comme une somme de
%   termes indépendants.
%
%   Exemples :
%      % Trois traitements (colonnes), deux blocs (lignes), sans repetition
%      y = [12 15 20; 13 16 22];
%      anova2(y)
%
%      % Deux repetitions par case
%      y = [10 12; 11 13; 20 25; 21 24];
%      anova2(y, 2)
%
%   Voir aussi ANOVA1, KRUSKALWALLIS, FRIEDMAN, MULTCOMPARE.
    if nargin < 2 || isempty(repetitions)
        repetitions = 1;
    end
    [lignes, colonnes] = size(y);
    if mod(lignes, repetitions) ~= 0
        error('stats:anova2:BadReps', ...
              'The number of rows must be a multiple of REPS.');
    end
    niveauxLignes = lignes / repetitions;
    n = lignes * colonnes;
    moyenneGenerale = mean(y(:));

    % Moyennes marginales.
    moyenneColonne = mean(y, 1);
    moyenneLigne = zeros(niveauxLignes, 1);
    for i = 1:niveauxLignes
        bloc = y((i - 1) * repetitions + 1:i * repetitions, :);
        moyenneLigne(i) = mean(bloc(:));
    end

    sceColonnes = repetitions * niveauxLignes * ...
                  sum((moyenneColonne - moyenneGenerale) .^ 2);
    sceLignes = repetitions * colonnes * sum((moyenneLigne - moyenneGenerale) .^ 2);
    sceTotal = sum((y(:) - moyenneGenerale) .^ 2);

    if repetitions > 1
        % Moyenne de chaque case, d'où l'interaction et l'erreur.
        sceCases = 0;
        sceErreur = 0;
        for i = 1:niveauxLignes
            for j = 1:colonnes
                case_ = y((i - 1) * repetitions + 1:i * repetitions, j);
                mc = mean(case_);
                sceCases = sceCases + repetitions * (mc - moyenneGenerale) ^ 2;
                sceErreur = sceErreur + sum((case_ - mc) .^ 2);
            end
        end
        sceInteraction = sceCases - sceColonnes - sceLignes;
        ddlColonnes = colonnes - 1;
        ddlLignes = niveauxLignes - 1;
        ddlInteraction = ddlColonnes * ddlLignes;
        ddlErreur = n - niveauxLignes * colonnes;
    else
        sceInteraction = 0;
        sceErreur = sceTotal - sceColonnes - sceLignes;
        ddlColonnes = colonnes - 1;
        ddlLignes = niveauxLignes - 1;
        ddlInteraction = 0;
        ddlErreur = ddlColonnes * ddlLignes;
    end

    cmErreur = sceErreur / max(ddlErreur, 1);
    Fcolonnes = (sceColonnes / max(ddlColonnes, 1)) / cmErreur;
    Flignes = (sceLignes / max(ddlLignes, 1)) / cmErreur;
    p = [1 - fcdf(Fcolonnes, ddlColonnes, ddlErreur), ...
         1 - fcdf(Flignes, ddlLignes, ddlErreur)];
    Finteraction = NaN;
    if repetitions > 1
        Finteraction = (sceInteraction / max(ddlInteraction, 1)) / cmErreur;
        p = [p, 1 - fcdf(Finteraction, ddlInteraction, ddlErreur)];
    end
    tableau = struct('SSC', sceColonnes, 'SSR', sceLignes, ...
                     'SSI', sceInteraction, 'SSE', sceErreur, 'SST', sceTotal, ...
                     'dfC', ddlColonnes, 'dfR', ddlLignes, 'dfI', ddlInteraction, ...
                     'dfE', ddlErreur, 'MSE', cmErreur, ...
                     'Fc', Fcolonnes, 'Fr', Flignes, 'Fi', Finteraction);
end
