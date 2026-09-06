function x = nbininv(y, r, p)
%NBININV Quantile de la loi binomiale négative.
%   X = NBININV(P,R,PROB) rend le nombre d'échecs au-dessous duquel on
%   reste avec la probabilité P, avant le R-ième succès.
%
%   Elle généralise la géométrique — qui en est le cas R = 1 — et sert de
%   loi de comptage surdispersée : là où Poisson impose variance égale à
%   la moyenne, elle laisse la variance libre. C'est pourquoi on l'emploie
%   dès que les données sont plus dispersées que Poisson ne l'admet.
%
%   Exemple :
%      nbininv(0.5, 1, 0.5)            % le cas geometrique
%
%   Voir aussi NBINCDF, NBINPDF, GEOINV, POISSINV.
    [y, r, p] = statAjuster(y, r, p);
    x = zeros(size(y));
    for k = 1:numel(y)
        if ~(y(k) >= 0 && y(k) <= 1) || r(k) <= 0 || p(k) <= 0 || p(k) > 1
            x(k) = NaN;
            continue
        end
        if y(k) == 1 && p(k) < 1, x(k) = Inf; continue, end
        rr = r(k); pp = p(k);
        depart = round(rr * (1 - pp) / pp);
        x(k) = statQuantileDiscret(@(t) nbincdf(t, rr, pp), y(k), depart, 1e9);
    end
end
