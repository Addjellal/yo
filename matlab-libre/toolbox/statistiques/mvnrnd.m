function X = mvnrnd(mu, Sigma, n)
%MVNRND Tirages d'une loi normale multivariée.
%   X = MVNRND(MU,SIGMA) tire une observation de la loi normale de
%   moyenne MU et de covariance SIGMA, rendue en ligne. MU est un vecteur
%   de longueur P, SIGMA une matrice P x P symétrique définie positive.
%
%   X = MVNRND(MU,SIGMA,N) tire N observations, une par ligne.
%
%   Si MU est une matrice de N lignes, chaque ligne donne la moyenne de
%   l'observation correspondante, et N n'est pas nécessaire.
%
%   Le tirage passe par la factorisation de Cholesky : X = MU + Z*R où Z
%   est normal centré réduit et R le facteur triangulaire supérieur de
%   SIGMA. La covariance empirique de X tend donc bien vers SIGMA.
%
%   Exemples :
%      X = mvnrnd([0 0], [1 0.8; 0.8 1], 1000);
%      cov(X)                      % proche de [1 0.8; 0.8 1]
%      mean(X)                     % proche de [0 0]
%
%      % Un nuage etire dans une direction :
%      X = mvnrnd([5 5], [4 0; 0 0.25], 200);
%      plot(X(:,1), X(:,2), '.'); axis('equal');
%
%   Voir aussi MVNPDF, MVNCDF, RANDN, NORMRND, CHOL, COV.
    if isvector(mu)
        mu = mu(:)';
    end
    p = size(mu, 2);
    if nargin < 3 || isempty(n)
        n = size(mu, 1);
    end
    if size(mu, 1) == 1
        mu = repmat(mu, n, 1);
    elseif size(mu, 1) ~= n
        error('stats:mvnrnd:InputSizeMismatch', ...
              'MU must have one row, or N rows.');
    end
    if isvector(Sigma) && numel(Sigma) == p && p > 1
        Sigma = diag(Sigma);
    end
    if size(Sigma, 1) ~= p || size(Sigma, 2) ~= p
        error('stats:mvnrnd:BadCovariance', 'SIGMA must be P-by-P.');
    end
    [R, defaut] = chol(Sigma);
    if defaut ~= 0
        error('stats:mvnrnd:BadCovariance', ...
              'SIGMA must be symmetric and positive definite.');
    end
    X = mu + randn(n, p) * R;
end
