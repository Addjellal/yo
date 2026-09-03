function modele = fitrgp(X, y, varargin)
%FITRGP Régression par processus gaussien.
%   M = FITRGP(X,Y) ajuste un processus gaussien : au lieu de choisir une
%   forme de courbe, on suppose que deux points proches ont des valeurs
%   proches, et la prédiction est la moyenne conditionnelle qui en
%   découle. Elle passe par les points observés quand le bruit est
%   supposé nul, et s'accompagne d'une variance qui grandit là où l'on
%   n'a pas observé.
%
%   FITRGP(...,'KernelFunction',K) choisit la fonction de covariance :
%   'squaredexponential' (défaut), 'exponential', 'matern32',
%   'matern52'.
%   FITRGP(...,'KernelParameters',[L S]) donne la longueur
%   caractéristique et l'écart type du signal, 'Sigma',S l'écart type du
%   bruit, 'Standardize',true centre et réduit les colonnes.
%
%   [Y,VARIANCE] = PREDICT(M,X) rend la moyenne et la variance
%   prédictives.
%
%   Exemple :
%      rng(1);
%      X = linspace(0, 10, 30)';
%      y = sin(X) + 0.05 * randn(30, 1);
%      m = fitrgp(X, y, 'KernelParameters', [1 1], 'Sigma', 0.05);
%      [mu, variance] = predict(m, X);
%
%   Voir aussi PREDICT, FITRSVM, FITRTREE, FITLM.
    X = double(X);
    y = double(y(:));
    noyau = 'squaredexponential';
    longueur = [];
    signal = [];
    sigma = [];
    standardiser = false;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'kernelfunction',   noyau = lower(char(varargin{k+1}));
            case 'kernelparameters'
                parametres = double(varargin{k+1});
                longueur = parametres(1);
                if numel(parametres) > 1
                    signal = parametres(2);
                end
            case 'sigma',            sigma = double(varargin{k+1});
            case 'standardize',      standardiser = logical(varargin{k+1});
            case {'basisfunction', 'fitmethod', 'predictmethod', 'verbose'}
                % Acceptées et sans effet.
            otherwise
                error('stats:fitrgp:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    [Xs, centre, echelle] = standardiserSvm(X, standardiser);
    % Réglages par défaut à l'échelle des données, comme le fait MATLAB
    % en l'absence d'optimisation des hyperparamètres.
    if isempty(longueur)
        distances = pdist(Xs);
        if isempty(distances)
            longueur = 1;
        else
            longueur = max(mean(distances), eps);
        end
    end
    if isempty(signal)
        signal = max(std(y), eps);
    end
    if isempty(sigma)
        sigma = max(std(y) / 10, 1e-6);
    end
    moyenne = mean(y);
    K = noyauGp(Xs, Xs, noyau, longueur, signal);
    A = K + sigma ^ 2 * eye(size(K));
    poids = A \ (y - moyenne);
    modele = struct('type', 'gp', 'X', Xs, 'Y', y, 'Moyenne', moyenne, ...
                    'Poids', poids, 'Matrice', A, 'Noyau', noyau, ...
                    'Longueur', longueur, 'Signal', signal, 'Sigma', sigma, ...
                    'Centre', centre, 'Echelle', echelle, ...
                    'NumObservations', numel(y));
end
