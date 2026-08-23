function [a, e] = rc2poly(k, r0)
%RC2POLY Polynôme de prédiction à partir des coefficients de réflexion.
%   A = RC2POLY(K) applique la récurrence de Levinson dans le sens
%   direct. C'est l'inverse de POLY2RC.
%
%   [A,E] = RC2POLY(K,R0) rend aussi l'erreur de prédiction finale, à
%   partir de la puissance R0 du signal.
    k = double(k(:));
    a = 1;
    for m = 1:numel(k)
        a = [a 0] + k(m) * [0 conj(fliplr(a))];
    end
    if nargout > 1
        if nargin < 2 || isempty(r0), r0 = 1; end
        e = r0;
        for m = 1:numel(k)
            e = e * (1 - abs(k(m)) ^ 2);
        end
    end
end
