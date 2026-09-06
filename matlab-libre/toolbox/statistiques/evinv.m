function x = evinv(p, mu, sigma)
%EVINV Quantile de la loi des valeurs extrêmes.
%   X = EVINV(P,MU,SIGMA) rend le quantile de la loi de Gumbel de type I
%   pour les minima.
%
%   Elle décrit la limite du minimum d'un grand nombre de tirages, comme
%   la normale décrit celle de leur somme : c'est le théorème des valeurs
%   extrêmes, et c'est ce qui la rend incontournable en fiabilité et en
%   hydrologie — on y dimensionne sur des crues centennales, non sur des
%   moyennes.
%
%   Attention à la convention : MATLAB nomme « extreme value » la loi des
%   minima. Pour les maxima, il faut changer le signe.
%
%   Exemple :
%      evinv(0.5, 0, 1)                % la mediane
%      evcdf(evinv(0.7, 0, 1), 0, 1)   % 0.7
%
%   Voir aussi EVCDF, EVPDF, EVRND, GEVINV.
    if nargin < 2, mu = 0; end
    if nargin < 3, sigma = 1; end
    [p, mu, sigma] = statAjuster(p, mu, sigma);
    x = mu + sigma .* log(-log(1 - p));
    x(p == 0) = -Inf;
    x(p == 1) = Inf;
    x(p < 0 | p > 1 | sigma <= 0) = NaN;
end
