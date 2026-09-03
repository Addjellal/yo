function modele = fitcecoc(X, y, varargin)
%FITCECOC Classification à plusieurs classes par codes correcteurs.
%   M = FITCECOC(X,Y) ramène un problème à K classes à une collection de
%   problèmes binaires : par défaut, un par paire de classes — K(K-1)/2
%   modèles —, et la classe retenue est celle qui gagne le plus de duels.
%
%   FITCECOC(...,'Coding','onevsall') n'apprend qu'un modèle par classe,
%   chacun opposant sa classe à toutes les autres : K modèles au lieu de
%   K(K-1)/2, plus rapide mais moins sûr quand les classes se
%   chevauchent.
%   FITCECOC(...,'Learners',F) choisit l'apprenant binaire : une poignée
%   de fonction prenant (X,Y) et rendant un modèle utilisable par
%   PREDICT. FITCSVM par défaut.
%
%   Exemple :
%      rng(1);
%      X = [randn(40, 2); randn(40, 2) + 4; randn(40, 2) + [0 5]];
%      y = [ones(40, 1); 2 * ones(40, 1); 3 * ones(40, 1)];
%      m = fitcecoc(X, y);
%      mean(predict(m, X) == y)
%
%   Voir aussi PREDICT, FITCSVM, FITCNB, FITCTREE, MNRFIT.
    X = double(X);
    y = y(:);
    classes = unique(y);
    k = numel(classes);
    if k < 2
        error('stats:fitcecoc:Classes', 'Il faut au moins deux classes.');
    end
    codage = 'onevsone';
    apprenant = @(Xa, ya) fitcsvm(Xa, ya);
    j = 1;
    while j + 1 <= numel(varargin)
        switch lower(char(varargin{j}))
            case 'coding',   codage = lower(char(varargin{j+1}));
            case 'learners', apprenant = varargin{j+1};
            case {'classnames', 'prior', 'cost', 'verbose', 'crossval'}
                % Acceptées et sans effet.
            otherwise
                error('stats:fitcecoc:Option', 'Option inconnue : %s.', char(varargin{j}));
        end
        j = j + 2;
    end
    if ischar(apprenant) || isstring(apprenant)
        nom = lower(char(apprenant));
        switch nom
            case 'svm',            apprenant = @(Xa, ya) fitcsvm(Xa, ya);
            case 'naivebayes',     apprenant = @(Xa, ya) fitcnb(Xa, ya);
            case 'tree',           apprenant = @(Xa, ya) fitctree(Xa, ya);
            case 'knn',            apprenant = @(Xa, ya) fitcknn(Xa, ya);
            case 'linear',         apprenant = @(Xa, ya) fitclinear(Xa, ya);
            otherwise
                error('stats:fitcecoc:Learner', 'Apprenant inconnu : %s.', nom);
        end
    end
    modeles = {};
    paires = zeros(0, 2);
    switch codage
        case {'onevsone', 'one-versus-one'}
            for a = 1:(k - 1)
                for b = (a + 1):k
                    choix = (y == classes(a)) | (y == classes(b));
                    cible = zeros(sum(choix), 1);
                    sousY = y(choix);
                    cible(sousY == classes(a)) = -1;
                    cible(sousY == classes(b)) = 1;
                    modeles{end + 1} = apprenant(X(choix, :), cible);   %#ok<AGROW>
                    paires(end + 1, :) = [a, b];                        %#ok<AGROW>
                end
            end
        case {'onevsall', 'one-versus-all', 'onevsrest'}
            for a = 1:k
                cible = -ones(numel(y), 1);
                cible(y == classes(a)) = 1;
                modeles{end + 1} = apprenant(X, cible);   %#ok<AGROW>
                paires(end + 1, :) = [a, 0];              %#ok<AGROW>
            end
        otherwise
            error('stats:fitcecoc:Coding', 'Codage inconnu : %s.', codage);
    end
    modele = struct('type', 'ecoc', 'Classes', classes, 'Coding', codage, ...
                    'Modeles', {modeles}, 'Paires', paires, ...
                    'NumObservations', numel(y));
end
