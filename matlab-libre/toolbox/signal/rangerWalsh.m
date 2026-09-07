function y = rangerWalsh(x, ordre)
%RANGERWALSH Passe de l'ordre naturel à l'ordre demandé.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      y = rangerWalsh((1:8)', 'sequency');
%      numel(y)                    % 8
%
%   Voir aussi RANGERWALSHINVERSE, PERMUTATIONWALSH, FWHT.
    p = permutationWalsh(size(x, 1), ordre);
    y = x(p, :);
end
