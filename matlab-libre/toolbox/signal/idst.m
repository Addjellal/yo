function x = idst(y, n)
%IDST Transformée en sinus discrète inverse.
%   La matrice de la DST-I est symétrique et son carré vaut (N+1)/2 fois
%   l'identité : l'inverse n'est donc qu'un facteur d'échelle.
    y = double(y);
    ligne = isrow(y);
    if ligne, y = y(:); end
    if nargin >= 2 && ~isempty(n)
        if size(y, 1) > n
            y = y(1:n, :);
        else
            y(end+1:n, :) = 0;
        end
    end
    N = size(y, 1);
    if N == 0
        x = y;
        return
    end
    k = (1:N)';
    M = sin(pi * (k * k') / (N + 1));
    x = (2 / (N + 1)) * (M * y);
    if ligne, x = x.'; end
end
