function L = loss(modele, X, Y, varargin)
%LOSS Erreur d'un classifieur sur des données étiquetées.
%   L = LOSS(MDL,X,Y) applique le classifieur MDL aux observations X et
%   rend son erreur de classement : la part, pondérée, des observations
%   dont la classe prédite n'est pas Y.
%
%   Comme MATLAB, LOSS pondère chaque observation pour que les poids de
%   chaque classe totalisent sa probabilité a priori (champ Prior du
%   modèle). Avec les a priori empiriques, qui sont le défaut, c'est la
%   simple proportion d'erreurs ; avec 'Prior','uniform', chaque classe
%   pèse autant, quelle que soit sa taille.
%
%   L = LOSS(...,'LossFun',F) choisit la perte :
%      'classiferror'  l'erreur de classement ;
%      'mincost'       le coût minimal attendu — avec les coûts par défaut
%                      (zéro pour une bonne réponse, un sinon), c'est
%                      l'erreur de classement, ce qui est le défaut ;
%      une fonction    F(C,S,W,COST), où C est l'indicatrice logique des
%                      classes (une ligne par observation), S les scores,
%                      W les poids normalisés et COST la matrice des coûts.
%   L = LOSS(...,'Weights',W) pondère les observations avant
%   normalisation.
%
%   Les observations dont l'étiquette n'est pas une classe du modèle ne
%   comptent pas.
%
%   Exemple :
%      load fisheriris
%      Md = fitcdiscr(meas(1:2:end, :), species(1:2:end));
%      loss(Md, meas(2:2:end, :), species(2:2:end))   % erreur sur l'autre moitié
%
%   Voir aussi RESUBLOSS, RESUBPREDICT, PREDICT, CONFUSIONMAT.
    if ~isstruct(modele) || ~isfield(modele, 'type')
        error('stats:loss:BadModel', ...
              'LOSS attend un classifieur ajusté par une fonction fitc….');
    end
    perte = 'classiferror';
    poids = [];
    if mod(numel(varargin), 2) ~= 0
        error('stats:loss:BadNameValue', ...
              'LOSS : les options vont par paires, un nom et une valeur.');
    end
    for k = 1:2:numel(varargin)
        switch lower(char(varargin{k}))
            case 'lossfun'
                perte = varargin{k + 1};
                if ischar(perte) || isstring(perte)
                    perte = lower(char(perte));
                    if ~any(strcmp(perte, {'classiferror', 'mincost'}))
                        error('stats:loss:NotSupported', ...
                              ['LossFun ''%s'' n''est pas pris en charge par MatLibre : ' ...
                               '''classiferror'', ''mincost'' ou une fonction.'], perte);
                    end
                elseif ~isa(perte, 'function_handle')
                    error('stats:loss:BadLossFun', ...
                          'LossFun est un nom de perte ou une fonction.');
                end
            case 'weights'
                poids = double(varargin{k + 1});
                poids = poids(:);
            otherwise
                error('stats:loss:BadNameValue', 'LOSS n''a pas d''option ''%s''.', ...
                      char(varargin{k}));
        end
    end

    classes = classesDuModele(modele);
    Y = Y(:);
    n = numel(Y);
    if size(X, 1) ~= n
        error('stats:loss:BadSizes', ...
              'X et Y doivent avoir le même nombre d''observations.');
    end
    if isempty(poids)
        poids = ones(n, 1);
    elseif numel(poids) ~= n || any(poids < 0)
        error('stats:loss:BadWeights', ...
              'Weights compte un poids positif par observation.');
    end
    rangs = rangsDeClasse(Y, classes);
    connues = rangs > 0 & ~isnan(poids);
    K = numel(classes);

    % Les poids de chaque classe totalisent son a priori.
    if isfield(modele, 'Prior') && numel(modele.Prior) == K
        apriori = double(modele.Prior(:));
    else
        apriori = accumarray(rangs(connues), 1, [K 1]);
    end
    apriori = apriori / sum(apriori);
    w = zeros(n, 1);
    for c = 1:K
        dans = connues & rangs == c;
        total = sum(poids(dans));
        if total > 0
            w(dans) = poids(dans) / total * apriori(c);
        end
    end
    if sum(w) > 0
        w = w / sum(w);
    end

    [predites, scores] = predict(modele, X);
    rangsPredits = rangsDeClasse(predites(:), classes);
    if isa(perte, 'function_handle')
        C = false(n, K);
        C(sub2ind([n K], find(connues), rangs(connues))) = true;
        if isempty(scores)
            scores = double(C);
        end
        cout = ones(K) - eye(K);
        L = perte(C(connues, :), scores(connues, :), w(connues), cout);
    else
        erreurs = rangsPredits ~= rangs;
        L = sum(w(connues) .* erreurs(connues));
    end
end

function classes = classesDuModele(modele)
    if isfield(modele, 'ClassNames')
        classes = modele.ClassNames;
    elseif isfield(modele, 'Classes')
        classes = modele.Classes;
    elseif isfield(modele, 'Y')
        classes = unique(modele.Y);
    else
        error('stats:loss:BadModel', 'Le modèle ne dit pas quelles sont ses classes.');
    end
    classes = classes(:);
end

% Le rang de chaque étiquette parmi les classes du modèle, zéro si elle
% n'en est pas une.
function rangs = rangsDeClasse(Y, classes)
    if iscategorical(Y)
        Y = cellstr(Y);
    end
    if iscategorical(classes)
        classes = cellstr(classes);
    end
    if isstring(Y)
        Y = cellstr(Y);
    end
    if isstring(classes)
        classes = cellstr(classes);
    end
    if ischar(Y)
        Y = cellstr(Y);
    end
    if ischar(classes)
        classes = cellstr(classes);
    end
    [~, rangs] = ismember(Y, classes);
    rangs = double(rangs(:));
end
