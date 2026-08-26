function y = rangerWalshInverse(x, ordre)
%RANGERWALSHINVERSE Revient de l'ordre demandé à l'ordre naturel.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    p = permutationWalsh(size(x, 1), ordre);
    y = zeros(size(x));
    y(p, :) = x;
end
