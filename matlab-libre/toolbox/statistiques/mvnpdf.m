function y = mvnpdf(X, mu, Sigma)
%MVNPDF Densité de la loi normale multivariée.
%   Y = MVNPDF(X) évalue en chaque ligne de X la densité de la loi
%   normale centrée réduite de dimension P, où P est le nombre de
%   colonnes de X. Y a autant de lignes que X.
%
%   Y = MVNPDF(X,MU) prend MU pour moyenne, avec la covariance identité.
%   MU est un vecteur ligne de longueur P, ou une matrice de la taille de
%   X pour donner à chaque observation sa propre moyenne.
%
%   Y = MVNPDF(X,MU,SIGMA) prend SIGMA pour covariance. SIGMA est une
%   matrice P x P symétrique définie positive, ou un vecteur ligne de
%   longueur P si la covariance est diagonale.
%
%   La densité vaut
%
%      (2*pi)^(-P/2) * det(SIGMA)^(-1/2) * exp(-d/2)
%
%   où d est le carré de la distance de Mahalanobis de X à MU. Le calcul
%   passe par la factorisation de Cholesky : ni déterminant ni inverse
%   ne sont formés, ce qui reste exact pour un P élevé.
%
%   Exemples :
%      mvnpdf([0 0])                        % 0.15915 = 1/(2*pi)
%      mvnpdf([0 0], [0 0], [1 0; 0 1])     % la meme chose
%      mvnpdf([1 1; 0 0], [0 0], [2 1; 1 2])
%
%      % La densite le long d'une ligne, pour une loi correlee :
%      x = linspace(-3, 3, 7)';
%      mvnpdf([x, x], [0 0], [1 0.8; 0.8 1])
%
%   Voir aussi NORMPDF, MVNRND, MVNCDF, MAHAL, CHOL.
    if isvector(X) && size(X, 1) == 1
        % Une seule observation : MATLAB l'accepte en ligne.
    elseif isvector(X) && size(X, 2) == 1
        X = X';
    end
    p = size(X, 2);
    if nargin < 2 || isempty(mu)
        mu = zeros(1, p);
    end
    if nargin < 3 || isempty(Sigma)
        Sigma = eye(p);
    end
    if isvector(Sigma) && numel(Sigma) == p && p > 1
        Sigma = diag(Sigma);
    elseif isscalar(Sigma) && p == 1
        Sigma = Sigma;
    end
    n = size(X, 1);
    if isvector(mu) && numel(mu) == p
        mu = repmat(mu(:)', n, 1);
    end
    if ~isequal(size(mu), size(X))
        error('stats:mvnpdf:InputSizeMismatch', ...
              'MU must be a row vector of length P or the size of X.');
    end
    [R, defaut] = chol(Sigma);
    if defaut ~= 0
        error('stats:mvnpdf:BadCovariance', ...
              'SIGMA must be symmetric and positive definite.');
    end
    ecarts = X - mu;
    Z = (R' \ ecarts')';
    d = sum(Z .^ 2, 2);
    % log(det(Sigma)) = 2*somme(log(diag(R))) : sans former le determinant.
    logDet = 2 * sum(log(diag(R)));
    y = exp(-0.5 * (d + logDet + p * log(2 * pi)));
end
