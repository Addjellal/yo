function bhat = raylfit(x)
%RAYLFIT Estimation du paramètre d'une loi de Rayleigh.
%   Le maximum de vraisemblance vaut sqrt(sum(x^2)/(2n)).
%
%   Exemple :
%      rng(1);
%      abs(raylfit(raylrnd(2, 5000, 1)) - 2) < 0.1
%
%   Voir aussi RAYLPDF, RAYLCDF, RAYLINV, RAYLRND, PDF, CDF.
    x = double(x(:));
    bhat = sqrt(sum(x .^ 2) / (2 * numel(x)));
end
