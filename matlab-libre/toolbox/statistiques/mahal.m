function d = mahal(Y, X)
%MAHAL Distance de Mahalanobis au nuage de référence.
%   D = MAHAL(Y,X) rend, pour chaque ligne de Y, le carré de sa distance
%   de Mahalanobis au nuage X :
%
%      d = (y - m) * inv(C) * (y - m)'
%
%   où m est la moyenne des lignes de X et C leur covariance. C'est la
%   distance euclidienne mesurée après avoir blanchi les données : elle
%   tient compte de ce que les variables n'ont ni la même dispersion ni
%   la même corrélation. Un point à deux écarts types dans la direction
%   où le nuage est étroit est plus loin qu'un point à deux écarts types
%   là où il est large.
%
%   Y et X doivent avoir le même nombre de colonnes, et X doit compter
%   plus de lignes que de colonnes pour que la covariance soit
%   inversible.
%
%   Le calcul passe par la factorisation de Cholesky de C et une
%   résolution triangulaire : on n'inverse pas la matrice.
%
%   Exemples :
%      X = randn(100, 2);
%      mahal([0 0], X)              % proche de 0 : au centre du nuage
%      mahal([5 5], X)              % grand : loin de tout
%
%      % Une ellipse, non un cercle : le nuage est corrélé.
%      X = randn(500, 2) * [1 0; 0.9 0.4];
%      [mahal([1 1], X), mahal([1 -1], X)]
%
%   Voir aussi PDIST, PDIST2, COV, CHOL, KNNSEARCH.
    if size(Y, 2) ~= size(X, 2)
        error('stats:mahal:InputSizeMismatch', ...
              'Y and X must have the same number of columns.');
    end
    n = size(X, 1);
    p = size(X, 2);
    if n <= p
        error('stats:mahal:TooFewRows', ...
              'X must have more rows than columns.');
    end
    m = mean(X, 1);
    C = cov(X);
    [R, defaut] = chol(C);
    if defaut ~= 0
        error('stats:mahal:SingularCovariance', ...
              'The covariance of X is singular.');
    end
    % C = R'*R : (y-m) inv(C) (y-m)' = || (R')^-1 (y-m)' ||^2.
    ecarts = Y - repmat(m, size(Y, 1), 1);
    Z = (R' \ ecarts')';
    d = sum(Z .^ 2, 2);
end
