function bhat = raylfit(x)
%RAYLFIT Estimation du paramètre d'une loi de Rayleigh.
%   Le maximum de vraisemblance vaut sqrt(sum(x^2)/(2n)).
    x = double(x(:));
    bhat = sqrt(sum(x .^ 2) / (2 * numel(x)));
end
