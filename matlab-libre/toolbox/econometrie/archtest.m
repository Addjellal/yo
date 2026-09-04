function [rejet, pValeur, statistique, valeurCritique] = archtest(residus, varargin)
%ARCHTEST Test d'hétéroscédasticité conditionnelle.
%   H = ARCHTEST(R) teste si la variance de R dépend du passé. H vaut un
%   quand l'hypothèse d'homoscédasticité est rejetée : la série connaît
%   des périodes calmes et des périodes agitées, ce qu'un modèle GARCH
%   sait décrire.
%
%   ARCHTEST(...,'Lags',L) choisit le nombre de retards (un par défaut),
%   'Alpha',A le seuil (0,05).
%   [H,P,STAT,CRIT] = ARCHTEST(...) rend la valeur p, la statistique et
%   la valeur critique.
%
%   Le test est celui d'Engle : on régresse le carré des résidus sur ses
%   propres retards, et la statistique vaut N fois le coefficient de
%   détermination. Elle suit un khi-deux à L degrés de liberté sous
%   l'hypothèse nulle.
%
%   Exemple :
%      archtest(randn(1, 300))        % 0 : variance constante
%      bruit = randn(1, 300) .* [ones(1, 150), 5 * ones(1, 150)];
%      archtest(bruit, 'Lags', 2)     % souvent 1 : la variance change
%
%   Voir aussi LBQTEST, GARCH, AUTOCORR, OLS.
    residus = double(residus(:));
    n = numel(residus);
    retards = 1;
    alpha = 0.05;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'lags',  retards = round(varargin{k+1});
            case 'alpha', alpha = varargin{k+1};
            otherwise
                error('econ:archtest:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if retards < 1 || retards >= n - 1
        error('econ:archtest:Retards', ...
              'Le nombre de retards doit rester entre un et %d.', n - 2);
    end
    carres = (residus - mean(residus)) .^ 2;
    % Régression du carré sur ses retards : y = a0 + a1 y(-1) + ...
    y = carres((retards + 1):end);
    X = ones(numel(y), retards + 1);
    for j = 1:retards
        X(:, j + 1) = carres((retards + 1 - j):(end - j));
    end
    coefficients = X \ y;
    residuels = y - X * coefficients;
    totale = sum((y - mean(y)) .^ 2);
    if totale > 0
        r2 = 1 - sum(residuels .^ 2) / totale;
    else
        r2 = 0;
    end
    statistique = numel(y) * r2;
    pValeur = 1 - chi2cdf(statistique, retards);
    valeurCritique = chi2inv(1 - alpha, retards);
    rejet = pValeur < alpha;
end
