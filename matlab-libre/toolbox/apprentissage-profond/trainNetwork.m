function reseau = trainNetwork(X, Y, couches, options)
%TRAINNETWORK Apprentissage d'un réseau par rétropropagation.
%   RESEAU = TRAINNETWORK(X,Y,COUCHES,OPTIONS) apprend à associer les
%   colonnes de X (une observation par colonne) aux colonnes de Y.
%
%   Le coût est l'entropie croisée si la dernière couche est un softmax,
%   l'erreur quadratique sinon. La descente est stochastique avec inertie.
    if nargin < 4
        options = trainingOptions('sgdm');
    end
    n = size(X, 2);
    entree = size(X, 1);
    % Initialisation de Glorot.
    taille = entree;
    for k = 1:numel(couches)
        c = couches{k};
        if strcmp(c.type, 'fc')
            limite = sqrt(6 / (taille + c.sorties));
            c.W = (rand(c.sorties, taille) * 2 - 1) * limite;
            c.b = zeros(c.sorties, 1);
            taille = c.sorties;
            couches{k} = c;
        end
    end
    % Les couches de sortie de MATLAB ne transforment rien : elles ne
    % font que déclarer le coût. On les retire après en avoir lu le sens.
    entropie = strcmp(couches{end}.type, 'softmax');
    if strcmp(couches{end}.type, 'classification')
        entropie = numel(couches) > 1 && strcmp(couches{end-1}.type, 'softmax');
        couches(end) = [];
    elseif strcmp(couches{end}.type, 'regression')
        entropie = false;
        couches(end) = [];
    end
    couches = couches(~cellfun(@(c) strcmp(c.type, 'input'), couches));
    vitesseW = cell(numel(couches), 1);
    vitesseB = cell(numel(couches), 1);
    for k = 1:numel(couches)
        vitesseW{k} = 0;
        vitesseB{k} = 0;
    end
    taux = options.InitialLearnRate;
    for epoque = 1:options.MaxEpochs
        ordre = randperm(n);
        debut = 1;
        while debut <= n
            fin = min(n, debut + options.MiniBatchSize - 1);
            lot = ordre(debut:fin);
            xb = X(:, lot);
            yb = Y(:, lot);
            [couches, gW, gB] = passe(couches, xb, yb, entropie);
            for k = 1:numel(couches)
                if strcmp(couches{k}.type, 'fc')
                    vitesseW{k} = options.Momentum * vitesseW{k} - taux * gW{k};
                    vitesseB{k} = options.Momentum * vitesseB{k} - taux * gB{k};
                    couches{k}.W = couches{k}.W + vitesseW{k};
                    couches{k}.b = couches{k}.b + vitesseB{k};
                end
            end
            debut = fin + 1;
        end
        if options.Verbose && mod(epoque, max(1, round(options.MaxEpochs/10))) == 0
            sortie = propager(couches, X);
            if entropie
                cout = crossentropy(sortie, Y);
            else
                cout = mse(sortie, Y);
            end
            fprintf('epoque %4d   cout %.6f\n', epoque, cout);
        end
    end
    % Une cellule passée à STRUCT fabriquerait un tableau de structures :
    % on affecte les champs un à un pour garder la cellule intacte.
    reseau = struct();
    reseau.couches = couches;
    reseau.entree = entree;
    reseau.entropie = entropie;
end

function [couches, gW, gB] = passe(couches, x, y, entropie)
    % Propagation avant en mémorisant les entrées de chaque couche.
    activations = cell(numel(couches) + 1, 1);
    activations{1} = x;
    for k = 1:numel(couches)
        [activations{k+1}, couches{k}] = appliquerCouche(couches{k}, activations{k}, true);
    end
    m = size(x, 2);
    sortie = activations{end};
    if entropie
        delta = (sortie - y) / m;   % gradient combiné softmax + entropie
    else
        delta = 2 * (sortie - y) / m;
    end
    gW = cell(numel(couches), 1);
    gB = cell(numel(couches), 1);
    for k = numel(couches):-1:1
        c = couches{k};
        a = activations{k};
        switch c.type
            case 'fc'
                gW{k} = delta * a.';
                gB{k} = sum(delta, 2);
                delta = c.W.' * delta;
            case 'relu'
                delta = delta .* (activations{k+1} > 0);
            case 'leakyrelu'
                entree = activations{k};
                delta = delta .* ((entree > 0) + c.pente * (entree <= 0));
            case 'elu'
                entree = activations{k};
                delta = delta .* ((entree > 0) + ...
                                  (entree <= 0) .* (activations{k+1} + c.alpha));
            case 'dropout'
                if isfield(c, 'masque') && ~isempty(c.masque)
                    delta = delta .* c.masque / max(1 - c.probabilite, eps);
                end
            case 'batchnorm'
                gG = sum(delta .* c.centre, 2);
                gB2 = sum(delta, 2);
                couches{k}.gamma = c.gamma - 0.01 * gG;
                couches{k}.beta = c.beta - 0.01 * gB2;
                delta = delta .* repmat(c.gamma ./ sqrt(c.variance + c.epsilon), ...
                                        1, size(delta, 2));
            case 'sigmoid'
                s = activations{k+1};
                delta = delta .* s .* (1 - s);
            case 'tanh'
                s = activations{k+1};
                delta = delta .* (1 - s .^ 2);
            case 'softmax'
                if ~entropie
                    s = activations{k+1};
                    delta = delta .* s .* (1 - s);
                end
            otherwise
                gW{k} = 0;
                gB{k} = 0;
        end
        if ~strcmp(c.type, 'fc')
            gW{k} = 0;
            gB{k} = 0;
        end
    end
end

function [y, c] = appliquerCouche(c, x, apprentissage)
%APPLIQUERCOUCHE Propagation avant d'une couche.
%   APPRENTISSAGE distingue les couches qui se comportent autrement à
%   l'apprentissage : l'abandon et la normalisation par lot.
    if nargin < 3, apprentissage = false; end
    switch c.type
        case 'fc'
            y = c.W * x + repmat(c.b, 1, size(x, 2));
        case 'relu'
            y = relu(x);
        case 'leakyrelu'
            y = max(x, 0) + c.pente * min(x, 0);
        case 'elu'
            y = max(x, 0) + c.alpha * (exp(min(x, 0)) - 1);
        case 'sigmoid'
            y = sigmoid(x);
        case 'tanh'
            y = tanh(x);
        case 'softmax'
            y = softmax(x);
        case 'dropout'
            if apprentissage
                masque = rand(size(x)) >= c.probabilite;
                c.masque = masque;
                y = x .* masque / max(1 - c.probabilite, eps);
            else
                y = x;
            end
        case 'batchnorm'
            if isempty(c.gamma)
                c.gamma = ones(size(x, 1), 1);
                c.beta = zeros(size(x, 1), 1);
                c.moyenne = zeros(size(x, 1), 1);
                c.variance = ones(size(x, 1), 1);
            end
            if apprentissage && size(x, 2) > 1
                m = mean(x, 2);
                v = mean((x - repmat(m, 1, size(x, 2))).^2, 2);
                % Moyennes glissantes, comme dans MATLAB : facteur 0,1.
                c.moyenne = 0.9 * c.moyenne + 0.1 * m;
                c.variance = 0.9 * c.variance + 0.1 * v;
            else
                m = c.moyenne;
                v = c.variance;
            end
            centre = (x - repmat(m, 1, size(x, 2))) ./ repmat(sqrt(v + c.epsilon), 1, size(x, 2));
            c.centre = centre;
            y = repmat(c.gamma, 1, size(x, 2)) .* centre + repmat(c.beta, 1, size(x, 2));
        otherwise
            y = x;
    end
end

function y = propager(couches, x)
    y = x;
    for k = 1:numel(couches)
        y = appliquerCouche(couches{k}, y, false);
    end
end
