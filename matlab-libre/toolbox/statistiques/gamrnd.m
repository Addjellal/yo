function r = gamrnd(a, b, varargin)
%GAMRND Tirages d'une loi gamma de forme A et d'échelle B.
%   GAMRND(A,B), GAMRND(A,B,M), GAMRND(A,B,M,N), GAMRND(A,B,[M N]).
%
%   Méthode de Marsaglia et Tsang (2000) : pour une forme au moins égale
%   à 1 on pose d = a - 1/3, c = 1/sqrt(9d), et on accepte d*(1+c*z)^3
%   avec z normal selon un test en une ligne ; le taux d'acceptation
%   dépasse 95 %. Une forme inférieure à 1 se ramène à la précédente en
%   multipliant par u^(1/a). Tous les tirages sont menés de front, seuls
%   les refusés sont retirés au tour suivant.
    if nargin < 2, b = 1; end
    forme = statForme(size(a + b), varargin);
    a = statEtendre(a, forme);
    b = statEtendre(b, forme);
    valide = a > 0 & b > 0;
    petit = valide & a < 1;
    aa = a;
    aa(petit) = aa(petit) + 1;
    aa(~valide) = 1;
    d = aa - 1 / 3;
    c = 1 ./ sqrt(9 * d);
    r = zeros(forme);
    reste = valide;
    tours = 0;
    while any(reste(:)) && tours < 1000
        tours = tours + 1;
        indices = find(reste);
        dd = d(indices);
        cc = c(indices);
        % Les tirages prennent la forme de DD : rien ne se diffuse par
        % mégarde entre une ligne et une colonne.
        z = randn(size(dd));
        u = rand(size(dd));
        v = (1 + cc .* z) .^ 3;
        accepte = v > 0 & log(u) < 0.5 * z .^ 2 + dd - dd .* v + dd .* log(max(v, realmin));
        pris = indices(accepte);
        r(pris) = dd(accepte) .* v(accepte);
        reste(pris) = false;
    end
    if any(petit(:))
        q = a(petit);
        r(petit) = r(petit) .* rand(size(q)) .^ (1 ./ q);
    end
    r = r .* b;
    r(~valide) = NaN;
end
