function x = gaminv(p, a, b)
%GAMINV Quantile de la loi gamma de forme A et d'échelle B.
%   L'inversion se fait par dichotomie sur GAMMAINC, la gamma incomplète
%   régularisée : la répartition vaut gammainc(x/b, a).
%
%   Exemple :  gaminv(0.5, 1, 1)   % log(2) = 0.6931
    if nargin < 2, a = 1; end
    if nargin < 3, b = 1; end
    [p, a, b] = statAjuster(p, a, b);
    x = zeros(size(p));
    for k = 1:numel(p)
        cible = p(k);
        forme = a(k);
        if ~(cible >= 0 && cible <= 1) || forme <= 0 || b(k) <= 0
            x(k) = NaN;
            continue
        end
        if cible == 0, x(k) = 0; continue, end
        if cible == 1, x(k) = Inf; continue, end
        haut = max(1, forme);
        while gammainc(haut, forme) < cible && haut < 1e14
            haut = haut * 2;
        end
        bas = 0;
        for iteration = 1:200
            milieu = (bas + haut) / 2;
            if gammainc(milieu, forme) < cible
                bas = milieu;
            else
                haut = milieu;
            end
            if haut - bas <= 1e-14 * max(1, haut), break, end
        end
        x(k) = b(k) * (bas + haut) / 2;
    end
end
