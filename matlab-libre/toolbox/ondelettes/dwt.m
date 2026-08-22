function [approximation, detail] = dwt(x, nom)
%DWT Transformée en ondelettes discrète, un niveau.
%   [A,D] = DWT(X,NOM) rend l'approximation et le détail, sous-échantillonnés
%   d'un facteur deux. Les bords sont prolongés périodiquement.
    if nargin < 2
        nom = 'haar';
    end
    [Lo_D, Hi_D] = wfilters(nom);
    x = x(:).';
    n = numel(x);
    if mod(n, 2) == 1
        x = [x x(end)];
        n = n + 1;
    end
    f = numel(Lo_D);
    approximation = zeros(1, n / 2);
    detail = zeros(1, n / 2);
    for k = 1:n/2
        sa = 0;
        sd = 0;
        for j = 1:f
            indice = mod(2 * k - 2 + j - 1, n) + 1;
            sa = sa + Lo_D(j) * x(indice);
            sd = sd + Hi_D(j) * x(indice);
        end
        approximation(k) = sa;
        detail(k) = sd;
    end
end
