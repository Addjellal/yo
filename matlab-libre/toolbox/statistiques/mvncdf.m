function p = mvncdf(X, mu, Sigma, options)
%MVNCDF Répartition de la loi normale multivariée.
%   P = MVNCDF(X) rend, pour chaque ligne de X, la probabilité qu'un
%   tirage de la loi normale centrée réduite soit inférieur à X dans
%   toutes ses coordonnées à la fois.
%
%   P = MVNCDF(X,MU,SIGMA) prend MU pour moyenne et SIGMA pour
%   covariance.
%
%   P = MVNCDF(A,B,MU,SIGMA) rend la probabilité du pavé A < x < B.
%
%   En dimension un, le calcul est exact — c'est NORMCDF. En dimension
%   deux, il l'est aussi : la formule de Drezner-Wesolowsky donne la
%   probabilité par une seule intégrale sur l'angle, évaluée par
%   quadrature de Gauss. Au-delà, MatLibre intègre par tirages
%   quasi-aléatoires, et la valeur rendue porte une erreur de l'ordre du
%   millième.
%
%   Exemples :
%      mvncdf([0 0])                            % 0.25, par symetrie
%      mvncdf([0 0], [0 0], [1 0.5; 0.5 1])     % 0.3333
%      mvncdf([-1 -1], [1 1], [0 0], eye(2))    % le pave central
%      mvncdf(0)                                % 0.5, comme normcdf
%
%   Voir aussi MVNPDF, MVNRND, NORMCDF, MAHAL.
    if nargin >= 4 || (nargin == 3 && size(mu, 2) == size(X, 2) && ...
                       size(mu, 1) == size(X, 1) && ~isequal(size(Sigma), [1 1]) && ...
                       size(Sigma, 1) == 1)
        % Forme du pavé : MVNCDF(A,B,MU,SIGMA).
        A = X;
        B = mu;
        if nargin < 4
            options = eye(size(A, 2));
        end
        moyenne = Sigma;
        covariance = options;
        p = mvncdf(B, moyenne, covariance) - mvncdf(A, moyenne, covariance);
        return;
    end
    if isvector(X) && size(X, 1) > 1 && size(X, 2) == 1
        X = X';
    end
    d = size(X, 2);
    if nargin < 2 || isempty(mu)
        mu = zeros(1, d);
    end
    if nargin < 3 || isempty(Sigma)
        Sigma = eye(d);
    end
    if isvector(Sigma) && numel(Sigma) == d && d > 1
        Sigma = diag(Sigma);
    end
    mu = mu(:)';
    n = size(X, 1);
    p = zeros(n, 1);
    ecartType = sqrt(diag(Sigma));
    if d == 1
        p = normcdf((X - mu) ./ ecartType(1));
        return;
    end
    if d == 2
        rho = Sigma(1, 2) / (ecartType(1) * ecartType(2));
        for i = 1:n
            h = (X(i, 1) - mu(1)) / ecartType(1);
            k = (X(i, 2) - mu(2)) / ecartType(2);
            p(i) = matlibre_normale_bivariee(h, k, rho);
        end
        return;
    end
    % Au-delà de deux dimensions : intégration par tirages. Le germe est
    % fixé le temps du calcul, pour que deux appels identiques donnent la
    % même valeur — une répartition ne doit pas changer d'un appel à
    % l'autre.
    etat = rng();
    rng(20240117);
    tirages = 200000;
    Z = mvnrnd(zeros(1, d), Sigma, tirages);
    for i = 1:n
        seuil = X(i, :) - mu;
        dessous = true(tirages, 1);
        for j = 1:d
            dessous = dessous & (Z(:, j) <= seuil(j));
        end
        p(i) = sum(dessous) / tirages;
    end
    rng(etat);
end
