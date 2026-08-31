function [A, B, r, U, V, statistiques] = canoncorr(X, Y)
%CANONCORR Analyse des corrélations canoniques.
%   [A,B,R] = CANONCORR(X,Y) cherche les combinaisons linéaires des
%   colonnes de X et de celles de Y qui sont le plus corrélées entre
%   elles. A et B portent les coefficients de ces combinaisons, une par
%   colonne ; R donne les corrélations obtenues, en ordre décroissant.
%
%   C'est la généralisation de la corrélation à deux groupes de
%   variables : au lieu de demander comment une variable de X est liée à
%   une variable de Y, on demande comment l'ensemble X est lié à
%   l'ensemble Y. La première paire canonique est celle qui capte le plus
%   de ce lien, la deuxième la plus grande part de ce qui reste, et ainsi
%   de suite.
%
%   [A,B,R,U,V] = CANONCORR(X,Y) rend aussi les variables canoniques :
%   U = (X - moyenne) * A et V = (Y - moyenne) * B. La corrélation entre
%   U(:,k) et V(:,k) vaut R(k) ; toutes les autres paires sont
%   décorrélées.
%
%   [A,B,R,U,V,STATS] = CANONCORR(X,Y) rend le test de Bartlett de la
%   nullité des corrélations restantes : STATS.p(k) est la probabilité
%   critique de l'hypothèse « toutes les corrélations à partir de la
%   k-ième sont nulles ».
%
%   Le calcul passe par les factorisations QR de X et Y centrées, puis
%   par la décomposition en valeurs singulières de leur produit : c'est
%   la voie stable, qui n'inverse aucune matrice de covariance.
%
%   Exemples :
%      % Y depend de X par une seule combinaison
%      X = randn(100, 3);
%      Y = [X(:,1) - X(:,2), randn(100, 1)] + 0.1 * randn(100, 2);
%      [A, B, r] = canoncorr(X, Y);
%      r(1)                        % proche de 1
%      r(2)                        % beaucoup plus petit
%
%   Voir aussi CORR, PCA, PCACOV, REGRESS, SVD.
    n = size(X, 1);
    if size(Y, 1) ~= n
        error('stats:canoncorr:InputSizeMismatch', ...
              'X and Y must have the same number of rows.');
    end
    p = size(X, 2);
    q = size(Y, 2);
    Xc = X - repmat(mean(X, 1), n, 1);
    Yc = Y - repmat(mean(Y, 1), n, 1);
    [Qx, Rx] = qr(Xc, 0);
    [Qy, Ry] = qr(Yc, 0);
    % Le rang effectif : une colonne colinéaire aux autres n'apporte rien.
    rangX = rangEffectif(Rx);
    rangY = rangEffectif(Ry);
    Qx = Qx(:, 1:rangX);
    Rx = Rx(1:rangX, 1:rangX);
    Qy = Qy(:, 1:rangY);
    Ry = Ry(1:rangY, 1:rangY);
    d = min(rangX, rangY);
    [L, D, M] = svd(Qx' * Qy, 0);
    r = diag(D);
    r = r(1:d);
    r = max(0, min(1, r));
    facteur = sqrt(n - 1);
    A = zeros(p, d);
    B = zeros(q, d);
    A(1:rangX, :) = facteur * (Rx \ L(:, 1:d));
    B(1:rangY, :) = facteur * (Ry \ M(:, 1:d));
    U = Xc * A;
    V = Yc * B;
    % Test de Bartlett : le lambda de Wilks des corrélations restantes.
    lambda = ones(d, 1);
    for k = 1:d
        lambda(k) = prod(1 - r(k:d) .^ 2);
    end
    chi2 = zeros(d, 1);
    ddl = zeros(d, 1);
    valeursP = zeros(d, 1);
    for k = 1:d
        chi2(k) = -(n - 1 - (rangX + rangY + 1) / 2) * log(max(lambda(k), realmin));
        ddl(k) = (rangX - k + 1) * (rangY - k + 1);
        valeursP(k) = 1 - chi2cdf(chi2(k), ddl(k));
    end
    statistiques = struct('Wilks', lambda, 'chisq', chi2, 'pChisq', valeursP, ...
                          'df1', ddl, 'p', valeursP);
end

function r = rangEffectif(R)
%RANGEFFECTIF Combien de lignes de R sont au-dessus du bruit d'arrondi.
    d = abs(diag(R));
    if isempty(d)
        r = 0;
        return;
    end
    seuil = max(size(R)) * eps * max(d);
    r = sum(d > seuil);
    r = max(r, 1);
end
