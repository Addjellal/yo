function [valeursPropres, vecteurs, nombreEffectif, dimension, S00, S01] = matlibre_johansen(Y, retards, modele)
%MATLIBRE_JOHANSEN Régression de rang réduit du modèle à correction d'erreur.
%   Rend les valeurs propres de la corrélation canonique entre les
%   différences et les niveaux retardés, une fois retirées de l'un et de
%   l'autre les différences retardées et les termes déterministes. Ce
%   sont ces valeurs propres qui portent toute l'information sur le rang
%   de cointégration.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    Y = double(Y);
    [T, n] = size(Y);
    if T <= retards + 2
        error('econ:johansen:Observations', ...
              'Il faut plus de %d observations.', retards + 2);
    end
    differences = diff(Y);                 % lignes t = 2..T
    % Échantillon utile : t = retards+2 .. T, soit les lignes
    % retards+1 .. T-1 de « differences ».
    lignes = (retards + 1):(T - 1);
    Teff = numel(lignes);
    tempsUtile = (lignes + 1).';           % l'instant t de chaque ligne
    Z0 = differences(lignes, :);
    niveaux = Y(lignes, :);                % Y_{t-1}
    switch lower(modele)
        case 'h2'                          % ni constante ni tendance
            Z1 = niveaux;
            deterministe = zeros(Teff, 0);
        case 'h1*'                         % constante dans la cointégration
            Z1 = [niveaux, ones(Teff, 1)];
            deterministe = zeros(Teff, 0);
        case 'h1'                          % constante libre
            Z1 = niveaux;
            deterministe = ones(Teff, 1);
        case 'h*'                          % tendance dans la cointégration
            Z1 = [niveaux, tempsUtile];
            deterministe = ones(Teff, 1);
        case 'h'                           % tendance libre
            Z1 = niveaux;
            deterministe = [ones(Teff, 1), tempsUtile];
        otherwise
            error('econ:johansen:Modele', ...
                  'Le modèle vaut H2, H1*, H1, H* ou H, pas « %s ».', modele);
    end
    Z2 = deterministe;
    for j = 1:retards
        Z2 = [Z2, differences(lignes - j, :)];   %#ok<AGROW>
    end
    if isempty(Z2)
        R0 = Z0;
        R1 = Z1;
    else
        R0 = Z0 - Z2 * (Z2 \ Z0);
        R1 = Z1 - Z2 * (Z2 \ Z1);
    end
    S00 = (R0.' * R0) / Teff;
    S01 = (R0.' * R1) / Teff;
    S11 = (R1.' * R1) / Teff;
    % Problème aux valeurs propres |lambda S11 - S10 inv(S00) S01| = 0,
    % ramené à une forme symétrique par la factorisation de Cholesky.
    L = chol(S11 + eps * eye(size(S11)), 'lower');
    M = L \ (S01.' * (S00 \ S01)) / (L.');
    M = (M + M.') / 2;
    [vecteursM, lambda] = eig(M);
    lambda = real(diag(lambda));
    [lambda, ordre] = sort(lambda, 'descend');
    vecteursM = vecteursM(:, ordre);
    valeursPropres = min(max(lambda(1:n), 0), 1 - eps);
    % Vecteurs propres ramenés dans la base d'origine et normalisés par
    % b' S11 b = 1, ce qui rend alpha = S01 b directement lisible.
    vecteurs = (L.') \ vecteursM(:, 1:n);
    nombreEffectif = Teff;
    dimension = n;
end
