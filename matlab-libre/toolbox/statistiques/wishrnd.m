function [W, D] = wishrnd(Sigma, ddl, D)
%WISHRND Tirage d'une matrice de Wishart.
%   W = WISHRND(SIGMA,DF) tire une matrice de la loi de Wishart de
%   paramètre d'échelle SIGMA et de DF degrés de liberté. C'est la loi de
%   
%      W = somme des x_i * x_i'
%
%   où les x_i sont DF tirages indépendants d'une loi normale
%   multivariée centrée de covariance SIGMA. Autrement dit, c'est la loi
%   de la matrice des sommes de carrés et de produits croisés — celle
%   dont dépend la covariance empirique.
%
%   W = WISHRND(SIGMA,DF,D) emploie le facteur de Cholesky D de SIGMA
%   déjà calculé, ce qui évite de le refaire à chaque tirage.
%   [W,D] = WISHRND(SIGMA,DF) rend ce facteur, pour le réemployer.
%
%   DF n'a pas besoin d'être entier : le tirage passe par la
%   décomposition de Bartlett, où les carrés de la diagonale suivent des
%   lois du khi-deux à DF-i+1 degrés. C'est aussi ce qui le rend rapide :
%   il ne coûte pas DF tirages normaux, mais p(p+1)/2 tirages en tout.
%
%   L'espérance de W vaut DF*SIGMA.
%
%   Exemples :
%      S = [2 1; 1 3];
%      W = wishrnd(S, 10);
%      % Sur beaucoup de tirages, la moyenne tend vers 10*S
%      M = zeros(2); for k = 1:4000, M = M + wishrnd(S, 10); end
%      M / 4000
%
%   Voir aussi IWISHRND, MVNRND, COV, CHOL, CHI2RND.
    if (nargin < 1 || isempty(Sigma)) && nargin >= 3 && ~isempty(D)
        % La forme « wishrnd([],df,D) » : le facteur suffit, IWISHRND
        % l'emploie pour ne pas refactoriser a chaque tirage.
        Sigma = [];
        p = size(D, 1);
    else
        p = size(Sigma, 1);
        if size(Sigma, 2) ~= p
            error('stats:wishrnd:BadSigma', 'SIGMA must be square.');
        end
    end
    if ddl <= p - 1
        error('stats:wishrnd:BadDf', ...
              'The degrees of freedom must exceed the dimension minus one.');
    end
    if nargin < 3 || isempty(D)
        [D, defaut] = chol(Sigma);
        if defaut ~= 0
            error('stats:wishrnd:BadSigma', ...
                  'SIGMA must be symmetric and positive definite.');
        end
    end
    % Décomposition de Bartlett : une triangulaire inférieure dont la
    % diagonale porte des racines de khi-deux et le reste des normales.
    A = zeros(p, p);
    for i = 1:p
        A(i, i) = sqrt(chi2rnd(ddl - i + 1));
        for j = 1:i - 1
            A(i, j) = randn();
        end
    end
    % W = D' (A A') D : le produit est A A', non A' A — A est
    % triangulaire, les deux different, et l'esperance n'etait pas
    % df*SIGMA avec le mauvais.
    L = A' * D;
    W = L' * L;
    W = (W + W') / 2;
end
