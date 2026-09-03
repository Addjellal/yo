function modele = gmdistribution(mu, sigma, poids)
%GMDISTRIBUTION Mélange de lois gaussiennes.
%   M = GMDISTRIBUTION(MU,SIGMA) décrit un mélange dont MU donne les
%   moyennes — une ligne par composante — et SIGMA les covariances :
%   soit un tableau D×D×K de matrices pleines, soit un tableau 1×D×K de
%   variances si les composantes sont diagonales.
%
%   M = GMDISTRIBUTION(MU,SIGMA,P) donne le poids de chaque composante.
%   Sans P, elles pèsent également.
%
%   Le modèle rendu est une structure ; PDF, CDF, RANDOM et CLUSTER
%   l'acceptent, comme FITGMDIST qui l'ajuste sur des données.
%
%   Exemple :
%      m = gmdistribution([0 0; 3 3], cat(3, eye(2), eye(2)), [0.6 0.4]);
%      x = random(m, 500);
%      p = pdf(m, [0 0]);
%
%   Voir aussi FITGMDIST, PDF, RANDOM, CLUSTER, KMEANS, MVNPDF.
    mu = double(mu);
    k = size(mu, 1);
    d = size(mu, 2);
    sigma = double(sigma);
    diagonale = (size(sigma, 1) == 1 && d > 1);
    if nargin < 3 || isempty(poids)
        poids = ones(1, k) / k;
    end
    poids = double(poids(:)).';
    poids = poids / sum(poids);
    if size(sigma, 3) == 1 && k > 1
        % Une seule covariance, partagée par toutes les composantes.
        sigma = repmat(sigma, [1 1 k]);
    end
    modele = struct('type', 'melange-gaussien', 'mu', mu, 'Sigma', sigma, ...
                    'ComponentProportion', poids, 'NumComponents', k, ...
                    'NumVariables', d, 'SharedCovariance', false, ...
                    'DiagonalCovariance', diagonale, 'NLogL', NaN, ...
                    'Converged', true, 'NumIterations', 0);
end
