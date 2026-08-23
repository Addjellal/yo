function [sn, cn, dn] = ellipj(u, m, tol)
%ELLIPJ Fonctions elliptiques de Jacobi.
%   [SN,CN,DN] = ELLIPJ(U,M) évalue les trois fonctions au point U pour
%   le paramètre M = k^2.
%
%   La méthode est celle de la transformation de Landen descendante
%   (Abramowitz et Stegun 16.4) : on descend la suite arithmético-
%   géométrique, puis on remonte l'angle par arcsinus. Pour M = 0 on
%   retrouve le sinus et le cosinus ordinaires, pour M = 1 la tangente
%   et la sécante hyperboliques.
%
%   Exemple :
%      [s, c, d] = ellipj(0.5, 0);   % sin(0.5), cos(0.5), 1
    if nargin < 3 || isempty(tol), tol = eps; end
    u = double(u);
    m = double(m);
    if numel(m) == 1 && numel(u) > 1
        m = repmat(m, size(u));
    elseif numel(u) == 1 && numel(m) > 1
        u = repmat(u, size(m));
    end
    sn = zeros(size(u));
    cn = zeros(size(u));
    dn = zeros(size(u));
    for indice = 1:numel(u)
        [sn(indice), cn(indice), dn(indice)] = un(u(indice), m(indice), tol);
    end
end

function [sn, cn, dn] = un(u, m, tol)
    if m < 0 || m > 1 || isnan(m) || isnan(u)
        sn = NaN; cn = NaN; dn = NaN;
        return
    end
    if m == 0
        sn = sin(u); cn = cos(u); dn = 1;
        return
    end
    if m == 1
        sn = tanh(u); cn = sech(u); dn = sech(u);
        return
    end
    a = 1;
    b = sqrt(1 - m);
    c = sqrt(m);
    listeA = a;
    listeC = c;
    n = 0;
    while abs(c) > tol && n < 100
        n = n + 1;
        aSuivant = (a + b) / 2;
        bSuivant = sqrt(a * b);
        c = (a - b) / 2;
        a = aSuivant;
        b = bSuivant;
        listeA(n + 1) = a;      %#ok<AGROW>
        listeC(n + 1) = c;      %#ok<AGROW>
    end
    phi = 2 ^ n * listeA(n + 1) * u;
    for k = n:-1:1
        phi = (phi + asin(listeC(k + 1) / listeA(k + 1) * sin(phi))) / 2;
    end
    sn = sin(phi);
    cn = cos(phi);
    dn = sqrt(1 - m * sn ^ 2);
end
