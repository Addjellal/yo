function p = logncdf(x, mu, sigma)
%LOGNCDF Répartition de la loi log-normale.
%   P = LOGNCDF(X,MU,SIGMA) rend la probabilité qu'une variable dont le
%   logarithme est normal de moyenne MU et d'écart type SIGMA soit
%   inférieure à X.
%
%   Elle décrit ce qui résulte d'un produit de facteurs indépendants,
%   comme la normale décrit ce qui résulte d'une somme : d'où son emploi
%   pour les revenus, les tailles de particules, les cours de bourse.
%
%   MU et SIGMA sont ceux du logarithme, non de la variable : la moyenne
%   de la variable vaut exp(MU + SIGMA^2/2), et sa médiane exp(MU). Les
%   confondre est l'erreur la plus commune.
%
%   Exemple :
%      logncdf(1, 0, 1)                % 0.5 : la mediane est exp(0) = 1
%
%   Voir aussi LOGNPDF, LOGNINV, LOGNRND, NORMCDF.
    if nargin < 2, mu = 0; end
    if nargin < 3, sigma = 1; end
    p = zeros(size(x));
    positif = x > 0;
    p(positif) = normcdf((log(x(positif)) - mu) ./ sigma);
end
