function [rejet, pValeur, statistique, valeurCritique] = pptest(serie, varargin)
%PPTEST Test de racine unitaire de Phillips et Perron.
%   H = PPTEST(Y) teste si Y a une racine unitaire. H vaut un quand
%   l'hypothèse est rejetée : la série est stationnaire.
%
%   PPTEST(...,'Lags',L) choisit la fenêtre de la correction,
%   'Model',M le modèle — 'AR' sans constante, 'ARD' avec constante
%   (défaut), 'TS' avec constante et tendance —, 'Alpha',A le seuil.
%   [H,P,STAT,CRIT] = PPTEST(...) rend la valeur p, la statistique et la
%   valeur critique.
%
%   La différence avec ADFTEST tient à la façon de traiter
%   l'autocorrélation des résidus : au lieu d'ajouter des retards à la
%   régression, on corrige la statistique par une variance de long
%   terme. Le modèle reste donc à un seul retard, ce qui économise des
%   degrés de liberté.
%
%   Exemple :
%      pptest(randn(1, 200))          % 1 : pas de racine unitaire
%      pptest(cumsum(randn(1, 200)))  % 0 : il y en a une
%
%   Voir aussi ADFTEST, KPSSTEST, VRATIOTEST, LMCTEST.
    serie = double(serie(:));
    n = numel(serie);
    retards = max(1, floor(4 * (n / 100) ^ 0.25));
    modele = 'ard';
    alpha = 0.05;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'lags',  retards = round(varargin{k+1});
            case 'model', modele = lower(char(varargin{k+1}));
            case 'alpha', alpha = varargin{k+1};
            otherwise
                error('econ:pptest:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    y = serie(2:end);
    yRetarde = serie(1:end-1);
    m = numel(y);
    switch modele
        case 'ar',  X = yRetarde;
        case 'ard', X = [ones(m, 1), yRetarde];
        case 'ts',  X = [ones(m, 1), (1:m).', yRetarde];
        otherwise
            error('econ:pptest:Modele', ...
                  'Le modèle doit être ''AR'', ''ARD'' ou ''TS''.');
    end
    coefficients = X \ y;
    residus = y - X * coefficients;
    rho = coefficients(end);
    % Écart type du coefficient, par la matrice des covariances.
    variance = sum(residus .^ 2) / (m - size(X, 2));
    covariance = variance * inv(X.' * X);   %#ok<MINV>
    ecartType = sqrt(covariance(end, end));
    tBrut = (rho - 1) / ecartType;
    % Correction de Phillips et Perron : la variance de long terme
    % remplace la variance instantanée.
    sigmaCourt = sum(residus .^ 2) / m;
    sigmaLong = matlibre_newey_west(residus, retards);
    statistique = sqrt(sigmaCourt / sigmaLong) * tBrut - ...
                  (sigmaLong - sigmaCourt) * m * ecartType / (2 * sigmaLong * sqrt(sigmaCourt));
    [pValeur, valeurCritique] = matlibre_dickey_table(statistique, modele, alpha);
    rejet = statistique < valeurCritique;
end
