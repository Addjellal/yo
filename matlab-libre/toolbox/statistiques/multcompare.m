function [comparaisons, moyennes, H, noms] = multcompare(statistiques, varargin)
%MULTCOMPARE Comparaisons multiples après une analyse de variance.
%   C = MULTCOMPARE(STATS) compare les groupes deux à deux, à partir de
%   la structure STATS que rend ANOVA1, KRUSKALWALLIS ou FRIEDMAN. Une
%   analyse de variance dit que les groupes ne sont pas tous égaux ;
%   MULTCOMPARE dit lesquels diffèrent.
%
%   C compte une ligne par paire et six colonnes :
%      1, 2   les deux groupes comparés ;
%      3      la borne basse de l'intervalle de confiance de leur écart ;
%      4      l'écart estimé lui-même ;
%      5      la borne haute ;
%      6      la probabilité critique de la comparaison.
%
%   Une paire dont l'intervalle ne contient pas zéro diffère au seuil
%   retenu.
%
%   [C,M] = MULTCOMPARE(STATS) rend en outre, pour chaque groupe, son
%   estimation et son erreur type.
%   [C,M,H] = MULTCOMPARE(STATS) trace les intervalles.
%   [C,M,H,NOMS] = MULTCOMPARE(STATS) rend les noms des groupes.
%
%   MULTCOMPARE(...,'alpha',A) change le seuil, 0.05 par défaut.
%
%   MULTCOMPARE(...,'ctype',T) choisit la correction de la multiplicité :
%      'tukey-kramer'  la plage studentisée, exacte pour des groupes de
%                      même effectif et légèrement conservatrice sinon
%                      (défaut) ;
%      'bonferroni'    le seuil divisé par le nombre de paires : simple
%                      et toujours valable, mais prudent ;
%      'lsd'           aucune correction ; à ne prendre que si l'analyse
%                      de variance a déjà conclu.
%
%   Comparer K groupes deux à deux fait K(K-1)/2 tests : sans correction,
%   la chance de conclure à tort au moins une fois grandit vite avec K.
%   C'est tout l'objet de cette fonction.
%
%   Exemples :
%      y = [5 6 7 10 11 12 5.5 6.5 7.5];
%      g = [1 1 1 2 2 2 3 3 3];
%      [~, ~, stats] = anova1(y, g);
%      c = multcompare(stats)
%      % les paires 1-2 et 2-3 different, la paire 1-3 non
%
%   Voir aussi ANOVA1, ANOVA2, KRUSKALWALLIS, FRIEDMAN, TTEST2.
    alpha = 0.05;
    correction = 'tukey-kramer';
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        switch nom
            case 'alpha'
                alpha = varargin{k + 1};
            case 'ctype'
                correction = lower(char(varargin{k + 1}));
            case {'display', 'dimension', 'estimate'}
                % acceptés et sans effet
            otherwise
                error('stats:multcompare:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end

    source = 'anova1';
    if isfield(statistiques, 'source')
        source = statistiques.source;
    end
    effectifs = statistiques.n(:);
    K = numel(effectifs);
    if strcmp(source, 'kruskalwallis') || strcmp(source, 'friedman')
        estimations = statistiques.meanranks(:);
        % L'erreur type d'une différence de rangs moyens.
        if strcmp(source, 'friedman')
            sigma = statistiques.sigma;
            erreurPaire = @(i, j) sigma;
        else
            N = sum(effectifs);
            erreurPaire = @(i, j) sqrt(N * (N + 1) / 12 * ...
                                       (1 / effectifs(i) + 1 / effectifs(j)));
        end
        ddl = Inf;
    else
        estimations = statistiques.means(:);
        s = statistiques.s;
        ddl = statistiques.df;
        erreurPaire = @(i, j) s * sqrt(1 / effectifs(i) + 1 / effectifs(j));
    end
    noms = {};
    if isfield(statistiques, 'gnames')
        noms = statistiques.gnames;
    end
    if isempty(noms)
        noms = cell(K, 1);
        for i = 1:K
            noms{i} = num2str(i);
        end
    end

    nombrePaires = K * (K - 1) / 2;
    comparaisons = zeros(nombrePaires, 6);
    ligne = 0;
    for i = 1:K - 1
        for j = i + 1:K
            ligne = ligne + 1;
            ecart = estimations(i) - estimations(j);
            erreur_ = erreurPaire(i, j);
            [marge, pValeur] = matlibre_marge_comparaison(ecart, erreur_, alpha, ...
                                                          correction, K, ddl, ...
                                                          nombrePaires);
            comparaisons(ligne, :) = [i, j, ecart - marge, ecart, ecart + marge, pValeur];
        end
    end

    moyennes = zeros(K, 2);
    for i = 1:K
        moyennes(i, 1) = estimations(i);
        if strcmp(source, 'anova1')
            moyennes(i, 2) = statistiques.s / sqrt(effectifs(i));
        else
            moyennes(i, 2) = erreurPaire(i, i) / sqrt(2);
        end
    end

    H = [];
    if nargout >= 3 || nargout == 0
        marges = zeros(K, 1);
        for i = 1:K
            marges(i) = moyennes(i, 2) * 1.96;
        end
        errorbar(1:K, moyennes(:, 1), marges, 'o');
        xlim([0.5, K + 0.5]);
        xticks(1:K);
        xticklabels(noms);
        title('Comparaisons multiples');
    end
    if nargout == 0
        clear comparaisons;
    end
end
