function [x, valeur] = quadprog(H, f, A, b, Aeq, beq, bas, haut, x0)
%QUADPROG Programmation quadratique : minimise 0.5*x'Hx + f'x.
%   Les contraintes d'inégalité et les bornes sont traitées par
%   pénalisation ; le minimum est cherché par Nelder-Mead à partir de la
%   solution non contrainte.
    if nargin < 3, A = []; end
    if nargin < 4, b = []; end
    if nargin < 5, Aeq = []; end
    if nargin < 6, beq = []; end
    if nargin < 7, bas = []; end
    if nargin < 8, haut = []; end
    f = f(:);
    n = numel(f);
    if nargin < 9 || isempty(x0)
        if rank(H) == n
            x0 = -H \ f;
        else
            x0 = zeros(n, 1);
        end
    end
    objectif = @(v) 0.5 * v(:)' * H * v(:) + f' * v(:) + penalite(v(:), A, b, Aeq, beq, bas, haut);
    x = fminsearch(objectif, x0(:));
    x = x(:);
    if ~isempty(bas), x = max(x, bas(:)); end
    if ~isempty(haut), x = min(x, haut(:)); end
    valeur = 0.5 * x' * H * x + f' * x;
end

function p = penalite(x, A, b, Aeq, beq, bas, haut)
    p = 0;
    if ~isempty(A)
        d = A * x - b(:);
        p = p + 1e6 * sum(max(d, 0) .^ 2);
    end
    if ~isempty(Aeq)
        p = p + 1e6 * sum((Aeq * x - beq(:)) .^ 2);
    end
    if ~isempty(bas)
        p = p + 1e6 * sum(max(bas(:) - x, 0) .^ 2);
    end
    if ~isempty(haut)
        p = p + 1e6 * sum(max(x - haut(:), 0) .^ 2);
    end
end
