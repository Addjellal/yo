function y = fwht(x, n, ordre)
%FWHT Transformée de Walsh-Hadamard rapide.
%   Y = FWHT(X) transforme X, dont la longueur est complétée à la
%   puissance de deux supérieure. Le facteur 1/N est porté par la
%   transformée directe, comme dans MATLAB.
%
%   Y = FWHT(X,N) impose la longueur. Y = FWHT(X,N,ORDRE) choisit
%   l'ordre des fonctions de Walsh : 'sequency' (par défaut, rangées par
%   nombre de changements de signe), 'hadamard' (ordre naturel de la
%   construction de Sylvester) ou 'dyadic' (ordre de Paley).
%
%   Exemple :
%      fwht([1 0 0 0])   % [0.25 0.25 0.25 0.25]
    if nargin < 3, ordre = 'sequency'; end
    x = double(x);
    ligne = isrow(x);
    if ligne, x = x(:); end
    if nargin >= 2 && ~isempty(n)
        N = 2 ^ nextpow2(n);
    else
        N = 2 ^ nextpow2(size(x, 1));
    end
    if size(x, 1) > N
        x = x(1:N, :);
    elseif size(x, 1) < N
        x(end+1:N, :) = 0;
    end
    y = rangerWalsh(papillonHadamard(x) / N, ordre);
    if ligne, y = y.'; end
end
