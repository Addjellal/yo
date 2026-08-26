function x = betainv(p, a, b)
%BETAINV Quantile de la loi bêta.
%   Inversion par dichotomie de la bêta incomplète régularisée sur [0,1].
%
%   Exemple :  betainv(0.5, 1, 1)   % 0.5, la loi uniforme
    [p, a, b] = statAjuster(p, a, b);
    x = zeros(size(p));
    for k = 1:numel(p)
        cible = p(k);
        if ~(cible >= 0 && cible <= 1) || a(k) <= 0 || b(k) <= 0
            x(k) = NaN;
            continue
        end
        if cible == 0, x(k) = 0; continue, end
        if cible == 1, x(k) = 1; continue, end
        bas = 0;
        haut = 1;
        for iteration = 1:200
            milieu = (bas + haut) / 2;
            if betainc(milieu, a(k), b(k)) < cible
                bas = milieu;
            else
                haut = milieu;
            end
            if haut - bas <= 1e-15, break, end
        end
        x(k) = (bas + haut) / 2;
    end
end
