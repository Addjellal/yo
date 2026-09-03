function modele = fitcnb(X, y, varargin)
%FITCNB Classifieur bayésien naïf.
%   M = FITCNB(X,Y) ajuste un classifieur qui suppose les variables
%   indépendantes à l'intérieur de chaque classe. C'est une hypothèse
%   fausse presque partout, et pourtant le classifieur qu'elle donne est
%   souvent bon : l'indépendance ne sert qu'à estimer les densités, et
%   l'erreur qu'elle introduit se compense entre classes.
%
%   FITCNB(...,'DistributionNames','normal') suppose des variables
%   gaussiennes (défaut) ; 'kernel' emploie une estimation à noyau, 'mn'
%   traite les colonnes comme des comptes multinomiaux.
%   FITCNB(...,'Prior',P) impose les probabilités a priori des classes.
%
%   PREDICT applique le modèle.
%
%   Exemple :
%      rng(1);
%      X = [randn(50, 2); randn(50, 2) + 3];
%      y = [ones(50, 1); 2 * ones(50, 1)];
%      m = fitcnb(X, y);
%      mean(predict(m, X) == y)
%
%   Voir aussi PREDICT, FITCTREE, FITCKNN, FITCSVM, FITCECOC.
    X = double(X);
    y = y(:);
    [classes, ~, indices] = unique(y);
    k = numel(classes);
    distribution = 'normal';
    apriori = [];
    j = 1;
    while j + 1 <= numel(varargin)
        switch lower(char(varargin{j}))
            case 'distributionnames', distribution = lower(char(varargin{j+1}));
            case 'prior',             apriori = double(varargin{j+1}(:));
            case {'classnames', 'width', 'kernel'}
                % Acceptées et sans effet.
            otherwise
                error('stats:fitcnb:Option', 'Option inconnue : %s.', char(varargin{j}));
        end
        j = j + 2;
    end
    p = size(X, 2);
    moyennes = zeros(k, p);
    ecarts = zeros(k, p);
    frequences = zeros(k, p);
    echantillons = cell(k, 1);
    compte = zeros(k, 1);
    for c = 1:k
        bloc = X(indices == c, :);
        compte(c) = size(bloc, 1);
        echantillons{c} = bloc;
        moyennes(c, :) = mean(bloc, 1);
        % Un écart type nul rendrait la densité infinie : on lui donne
        % un plancher, comme le fait MATLAB.
        ecarts(c, :) = max(std(bloc, 0, 1), 1e-10);
        if strcmp(distribution, 'mn')
            % Comptes multinomiaux, lissés à la Laplace.
            sommes = sum(bloc, 1) + 1;
            frequences(c, :) = sommes / sum(sommes);
        end
    end
    if isempty(apriori)
        apriori = compte / sum(compte);
    else
        apriori = apriori / sum(apriori);
    end
    modele = struct('type', 'bayes-naif', 'Classes', classes, ...
                    'Distribution', distribution, 'Mu', moyennes, ...
                    'Sigma', ecarts, 'Frequences', frequences, ...
                    'Prior', apriori, 'Echantillons', {echantillons}, ...
                    'NumObservations', numel(y));
end
