function [W, DI] = iwishrnd(Sigma, ddl, DI)
%IWISHRND Tirage d'une matrice de Wishart inverse.
%   W = IWISHRND(SIGMA,DF) tire une matrice de la loi de Wishart inverse
%   de paramètre SIGMA et de DF degrés de liberté : si X suit une
%   Wishart de paramètre inv(SIGMA) et de DF degrés, alors inv(X) suit
%   cette loi.
%
%   C'est la loi a priori conjuguée de la covariance d'une normale
%   multivariée : c'est à ce titre qu'on la rencontre en statistique
%   bayésienne.
%
%   W = IWISHRND(SIGMA,DF,DI) emploie le facteur de Cholesky DI de
%   inv(SIGMA) déjà calculé.
%   [W,DI] = IWISHRND(SIGMA,DF) le rend, pour le réemployer.
%
%   L'espérance de W vaut SIGMA/(DF-p-1) quand DF dépasse p+1.
%
%   Exemples :
%      S = [2 1; 1 3];
%      W = iwishrnd(S, 10);
%      M = zeros(2); for k = 1:4000, M = M + iwishrnd(S, 10); end
%      M / 4000              % proche de S/(10-2-1)
%
%   Voir aussi WISHRND, MVNRND, CHOL, COV.
    p = size(Sigma, 1);
    if nargin < 3 || isempty(DI)
        [DI, defaut] = chol(inv(Sigma));
        if defaut ~= 0
            error('stats:iwishrnd:BadSigma', ...
                  'SIGMA must be symmetric and positive definite.');
        end
    end
    X = wishrnd([], ddl, DI);
    W = inv(X);
    W = (W + W') / 2;
end
