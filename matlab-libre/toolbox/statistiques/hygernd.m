function r = hygernd(m, k, n, varargin)
%HYGERND Tirages d'une loi hypergéométrique.
%   Le support est fini et petit : quand les trois paramètres sont les
%   mêmes partout — le cas courant — la répartition est tabulée une fois
%   puis inversée d'un bloc.
    forme = statForme(size(m + k + n), varargin);
    m = statEtendre(m, forme);
    k = statEtendre(k, forme);
    n = statEtendre(n, forme);
    if numel(m) > 0 && all(m(:) == m(1)) && all(k(:) == k(1)) && all(n(:) == n(1))
        support = max(0, n(1) - (m(1) - k(1))):min(k(1), n(1));
        cumulee = cumsum(hygepdf(support, m(1), k(1), n(1)));
        u = rand(forme);
        r = repmat(support(end), forme);
        for j = numel(support):-1:1
            r(u <= cumulee(j)) = support(j);
        end
        r(isnan(cumulee(end))) = NaN;
    else
        r = hygeinv(rand(forme), m, k, n);
    end
end
