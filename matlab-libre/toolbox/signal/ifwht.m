function x = ifwht(y, n, ordre)
%IFWHT Transformée de Walsh-Hadamard inverse.
%   La transformée directe porte le facteur 1/N ; l'inverse n'en a pas.
%
%   Exemple :
%      ifwht(fwht([1 2 3 4]))   % [1 2 3 4]
    if nargin < 3, ordre = 'sequency'; end
    y = double(y);
    ligne = isrow(y);
    if ligne, y = y(:); end
    if nargin >= 2 && ~isempty(n)
        N = 2 ^ nextpow2(n);
        if size(y, 1) > N
            y = y(1:N, :);
        elseif size(y, 1) < N
            y(end+1:N, :) = 0;
        end
    else
        N = 2 ^ nextpow2(size(y, 1));
        if size(y, 1) < N, y(end+1:N, :) = 0; end
    end
    % La permutation est une involution une fois inversée : on remet les
    % lignes en ordre naturel avant le papillon.
    y = rangerWalshInverse(y, ordre);
    x = papillonHadamard(y);
    if ligne, x = x.'; end
end
