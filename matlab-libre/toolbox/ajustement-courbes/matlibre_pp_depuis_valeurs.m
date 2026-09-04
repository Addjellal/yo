function pp = matlibre_pp_depuis_valeurs(x, a, m)
%MATLIBRE_PP_DEPUIS_VALEURS Spline par morceaux, depuis valeurs et courbures.
%   PP = MATLIBRE_PP_DEPUIS_VALEURS(X,A,M) construit la forme par morceaux
%   d'une spline cubique dont on connaît les valeurs A et les dérivées
%   secondes M aux nœuds. Les coefficients de chaque morceau s'en
%   déduisent sans résoudre quoi que ce soit.
%
%   Exemple :
%      pp = matlibre_pp_depuis_valeurs([0;1;2], [0;1;0], [0;-2;0]);
%      ppval(pp, 1)      % 1
%
%   Voir aussi CSAPS, SPLINE, PPVAL.
    x = x(:);
    a = a(:);
    m = m(:);
    n = numel(x);
    h = diff(x);
    coefs = zeros(n - 1, 4);
    for i = 1:(n - 1)
        coefs(i, 1) = (m(i + 1) - m(i)) / (6 * h(i));
        coefs(i, 2) = m(i) / 2;
        coefs(i, 3) = (a(i + 1) - a(i)) / h(i) - h(i) * (2 * m(i) + m(i + 1)) / 6;
        coefs(i, 4) = a(i);
    end
    pp = struct('form', 'pp', 'breaks', x(:).', 'coefs', coefs, ...
                'pieces', n - 1, 'order', 4, 'dim', 1);
end
