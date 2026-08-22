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
    entropie = strcmp(couches{end}.type, 'softmax');
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
        activations{k+1} = appliquerCouche(couches{k}, activations{k});
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

function y = appliquerCouche(c, x)
    switch c.type
        case 'fc'
            y = c.W * x + repmat(c.b, 1, size(x, 2));
        case 'relu'
            y = relu(x);
        case 'sigmoid'
            y = sigmoid(x);
        case 'tanh'
            y = tanh(x);
        case 'softmax'
            y = softmax(x);
        otherwise
            y = x;
    end
end

function y = propager(couches, x)
    y = x;
    for k = 1:numel(couches)
        y = appliquerCouche(couches{k}, y);
    end
end
