function y = rangerWalshInverse(x, ordre)
%RANGERWALSHINVERSE Revient de l'ordre demandé à l'ordre naturel.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      x = (1:8)';
%      max(abs(rangerWalshInverse(rangerWalsh(x, 'sequency'), 'sequency') - x)) < 1e-12
    p = permutationWalsh(size(x, 1), ordre);
    y = zeros(size(x));
    y(p, :) = x;
end
