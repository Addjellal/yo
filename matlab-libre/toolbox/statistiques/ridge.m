function b = ridge(y, X, k, echelle)
%RIDGE Régression pénalisée par la norme des coefficients.
%   B = RIDGE(Y,X,K) résout
%
%      minimiser  ||y - X*b||^2 + K * ||b||^2
%
%   au lieu des seuls moindres carrés. Quand les colonnes de X sont
%   presque colinéaires, les moindres carrés donnent des coefficients
%   énormes et de signes contraires, qui se compensent ; la pénalité les
%   ramène vers zéro et rend l'ajustement stable, au prix d'un biais.
%
%   Par défaut X est centré et réduit avant l'ajustement, et B est rendu
%   dans cette échelle-là, sans terme constant : c'est ainsi que K a le
%   même sens pour toutes les colonnes.
%
%   B = RIDGE(Y,X,K,0) ramène ensuite les coefficients à l'échelle
%   d'origine et ajoute le terme constant en première ligne, de sorte
%   que Y s'estime par [1 X]*B.
%
%   K peut être un vecteur : B a alors une colonne par valeur, ce qui
%   donne la trace de la régression pénalisée — le dessin des
%   coefficients en fonction de la pénalité, dont on se sert pour
%   choisir K.
%
%   Exemples :
%      % Deux colonnes presque identiques
%      x1 = (1:20)';
%      X = [x1, x1 + randn(20, 1) * 0.01];
%      y = 3 * x1 + randn(20, 1);
%      X \ y                        % coefficients enormes et opposes
%      ridge(y, X, 1)               % ramenes pres l'un de l'autre
%
%      trace = ridge(y, X, 0:0.5:10);
%      plot(0:0.5:10, trace');      % la trace de la penalisation
%
%   Voir aussi REGRESS, ROBUSTFIT, LASSO, PCA, FITLM.
    if nargin < 4 || isempty(echelle)
        echelle = 1;
    end
    y = y(:);
    n = numel(y);
    if size(X, 1) ~= n
        error('stats:ridge:InputSizeMismatch', ...
              'X must have one row per observation.');
    end
    p = size(X, 2);
    moyennes = mean(X, 1);
    ecarts = std(X, 0, 1);
    ecarts(ecarts == 0) = 1;
    Z = (X - repmat(moyennes, n, 1)) ./ repmat(ecarts, n, 1);
    yc = y - mean(y);
    k = k(:)';
    b = zeros(p, numel(k));
    ZtZ = Z' * Z;
    Zty = Z' * yc;
    for j = 1:numel(k)
        b(:, j) = (ZtZ + k(j) * eye(p)) \ Zty;
    end
    if echelle == 0
        % Retour à l'échelle d'origine, terme constant en tête.
        brut = zeros(p + 1, numel(k));
        for j = 1:numel(k)
            coefficients = b(:, j) ./ ecarts';
            brut(2:end, j) = coefficients;
            brut(1, j) = mean(y) - moyennes * coefficients;
        end
        b = brut;
    end
end
