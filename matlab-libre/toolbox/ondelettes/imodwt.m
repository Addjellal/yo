function x = imodwt(w, nom)
%IMODWT Transformée à chevauchement maximal inverse.
%   Reconstruction exacte : la MODWT est un cadre ajusté de constante 1.
    if nargin < 2 || isempty(nom), nom = 'haar'; end
    [Lo_D, Hi_D] = wfilters(nom, 'r');
    bas = Lo_D / sqrt(2);
    haut = Hi_D / sqrt(2);
    niveaux = size(w, 1) - 1;
    courant = w(niveaux + 1, :);
    for k = niveaux:-1:1
        [basK, hautK] = dilaterFiltres(bas, haut, k - 1);
        courant = adjointCirculaireModwt(courant, basK) + ...
                  adjointCirculaireModwt(w(k, :), hautK);
    end
    x = courant;
end

function y = adjointCirculaireModwt(x, h)
    n = numel(x);
    m = numel(h);
    y = zeros(1, n);
    for k = 1:n
        for j = 1:m
            indice = mod(k - 1 + j - 1, n) + 1;
            y(indice) = y(indice) + h(j) * x(k);
        end
    end
end
