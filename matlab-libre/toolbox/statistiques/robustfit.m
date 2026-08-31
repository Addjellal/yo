function [b, statistiques] = robustfit(X, y, fonctionPoids, reglage, constante)
%ROBUSTFIT Régression linéaire robuste, par moindres carrés repondérés.
%   B = ROBUSTFIT(X,Y) ajuste Y = B(1) + X*B(2:end) en donnant moins de
%   poids aux observations qui s'écartent du modèle. Une seule valeur
%   aberrante suffit à faire basculer une régression ordinaire ;
%   ROBUSTFIT la reconnaît à son résidu et la fait taire.
%
%   La méthode est celle des moindres carrés repondérés : on ajuste, on
%   mesure les résidus, on en tire un poids par observation, on réajuste,
%   et l'on recommence jusqu'à ce que les coefficients ne bougent plus.
%
%   B = ROBUSTFIT(X,Y,POIDS) choisit la fonction de poids :
%      'bisquare'   celle de Tukey, qui annule le poids au-delà du
%                   réglage (défaut) ;
%      'huber'      poids en 1/|r| au-delà du réglage : moins brutale,
%                   elle ne rejette jamais tout à fait ;
%      'andrews', 'cauchy', 'fair', 'logistic', 'talwar', 'welsch'
%                   les autres fonctions de MATLAB ;
%      'ols'        aucun repondérage : les moindres carrés ordinaires.
%   POIDS peut aussi être une poignée @(r) …, qui rend le poids à partir
%   du résidu réduit.
%
%   B = ROBUSTFIT(X,Y,POIDS,REGLAGE) change la constante de réglage.
%   B = ROBUSTFIT(X,Y,POIDS,REGLAGE,'off') n'ajoute pas de terme
%   constant : X est pris tel quel.
%
%   [B,STATS] = ROBUSTFIT(...) rend en outre les résidus, les poids
%   finaux, l'écart type robuste et les erreurs types des coefficients.
%
%   Exemples :
%      x = (1:20)';
%      y = 2 * x + 1;
%      y(10) = 100;                    % une valeur aberrante
%      [x ones(20,1)] \ y              % les moindres carres : fausses
%      robustfit(x, y)                 % proche de [1 ; 2]
%
%   Voir aussi REGRESS, FITLM, POLYFIT, RIDGE, LSCOV.
    if nargin < 3 || isempty(fonctionPoids)
        fonctionPoids = 'bisquare';
    end
    if nargin < 4 || isempty(reglage)
        reglage = [];
    end
    if nargin < 5 || isempty(constante)
        constante = 'on';
    end
    y = y(:);
    if isvector(X) && numel(X) == numel(y)
        X = X(:);
    end
    n = numel(y);
    if strcmpi(char(constante), 'on')
        A = [ones(n, 1), X];
    else
        A = X;
    end
    p = size(A, 2);
    [poids, reglageDefaut] = matlibre_poids_robuste(fonctionPoids);
    if isempty(reglage)
        reglage = reglageDefaut;
    end

    b = A \ y;
    w = ones(n, 1);
    ddl = max(n - p, 1);
    for iteration = 1:100
        r = y - A * b;
        % L'écart type robuste : l'écart absolu médian, ramené à celui
        % d'une normale par le facteur 0.6745. Le facteur 1/(1-p/n)
        % corrige la perte de degrés de liberté.
        s = median(abs(r - median(r))) / 0.6745;
        if s < 1e-12 * max(1, max(abs(y)))
            s = 1e-12 * max(1, max(abs(y)));
        end
        s = s / max(sqrt(1 - p / n), 0.1);
        w = poids(r / (reglage * s));
        w = max(w, 0);
        ancien = b;
        % Moindres carrés pondérés : on multiplie chaque ligne par la
        % racine de son poids.
        racine = sqrt(w);
        b = (A .* repmat(racine, 1, p)) \ (y .* racine);
        if max(abs(b - ancien)) <= 1e-10 * max(1, max(abs(b)))
            break;
        end
    end
    r = y - A * b;
    s = median(abs(r - median(r))) / 0.6745;
    if s == 0
        s = sqrt(sum(w .* r .^ 2) / max(sum(w) - p, 1));
    end
    covariance = s ^ 2 * inv((A .* repmat(w, 1, p))' * A);
    erreurs = sqrt(abs(diag(covariance)));
    t = b ./ max(erreurs, eps);
    statistiques = struct('ols_s', norm(y - A * (A \ y)) / sqrt(ddl), ...
                          'robust_s', s, 's', s, 'se', erreurs, 't', t, ...
                          'p', 2 * (1 - tcdf(abs(t), ddl)), 'w', w, ...
                          'resid', r, 'dfe', ddl, 'coeffcorr', covariance);
end
