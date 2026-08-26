function y = hygepdf(x, m, k, n)
%HYGEPDF Probabilité de la loi hypergéométrique.
%   HYGEPDF(X,M,K,N) : tirage sans remise de N objets dans une population
%   de M, dont K portent le caractère cherché ; X est le nombre d'objets
%   marqués obtenus.
%
%   Exemple :  hygepdf(2, 10, 4, 3)   % 0.3
    [x, m, k, n] = statAjuster(x, m, k, n);
    y = zeros(size(x));
    for indice = 1:numel(x)
        y(indice) = terme(x(indice), m(indice), k(indice), n(indice));
    end
end

function p = terme(x, m, k, n)
    if m < 0 || k < 0 || n < 0 || k > m || n > m || ...
            m ~= round(m) || k ~= round(k) || n ~= round(n)
        p = NaN;
        return
    end
    if x ~= round(x) || x < max(0, n - (m - k)) || x > min(k, n)
        p = 0;
        return
    end
    % Le calcul passe par les logarithmes : les coefficients binomiaux
    % débordent bien avant leur rapport.
    p = exp(logChoisir(k, x) + logChoisir(m - k, n - x) - logChoisir(m, n));
end

function c = logChoisir(a, b)
    c = gammaln(a + 1) - gammaln(b + 1) - gammaln(a - b + 1);
end
