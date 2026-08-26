function [u, ia] = uniquetol(x, tol)
%UNIQUETOL Valeurs distinctes à une tolérance près.
%   U = UNIQUETOL(X,TOL) regroupe les valeurs dont l'écart relatif est
%   inférieur à TOL (1e-6 par défaut).
    if nargin < 2
        tol = 1e-6;
    end
    x = x(:);
    [trie, ordre] = sort(x);
    u = [];
    ia = [];
    echelle = max(abs(x));
    if isempty(echelle) || echelle == 0
        echelle = 1;
    end
    for k = 1:numel(trie)
        if isempty(u) || abs(trie(k) - u(end)) > tol * echelle
            u(end+1, 1) = trie(k);
            ia(end+1, 1) = ordre(k);
        end
    end
end
