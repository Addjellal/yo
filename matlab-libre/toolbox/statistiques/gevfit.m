function parametres = gevfit(x)
%GEVFIT Ajuste une loi généralisée des valeurs extrêmes.
%   P = GEVFIT(X) estime par maximum de vraisemblance les trois
%   paramètres de la loi GEV : P(1) la forme K, P(2) l'échelle SIGMA,
%   P(3) la position MU.
%
%   Le point de départ vient des moments : on ajuste d'abord une loi de
%   Gumbel — forme nulle — dont l'échelle et la position se lisent dans
%   la moyenne et l'écart type, puis on laisse la forme varier.
%
%   L'estimation par maximum de vraisemblance de la GEV n'est régulière
%   que pour K supérieur à -0.5 ; en deçà, la vraisemblance n'est pas
%   bornée et l'estimation peut ne pas converger. C'est une propriété de
%   la loi, non un défaut du calcul.
%
%   Exemples :
%      x = gevrnd(0.2, 1.5, 3, 2000, 1);
%      p = gevfit(x)                  % proche de [0.2 1.5 3]
%
%   Voir aussi GEVCDF, GEVPDF, GEVINV, GEVRND, MLE, WBLFIT.
    x = double(x(:));
    x = x(~isnan(x));
    if numel(x) < 3
        error('stats:gevfit:NotEnoughData', 'GEVFIT needs at least three values.');
    end
    sigma0 = std(x) * sqrt(6) / pi;
    if sigma0 <= 0
        sigma0 = 1;
    end
    mu0 = mean(x) - 0.5772156649015329 * sigma0;
    objectif = @(p) opposeeVraisemblance(p, x);
    depart = [0.1, sigma0, mu0];
    parametres = matlibre_nelder_mead(objectif, depart, 800, 1e-10);
end

function v = opposeeVraisemblance(p, x)
%OPPOSEEVRAISEMBLANCE L'opposé de la log-vraisemblance, à minimiser.
    k = p(1);
    sigma = p(2);
    mu = p(3);
    if sigma <= 0
        v = Inf;
        return;
    end
    densite = gevpdf(x, k, sigma, mu);
    if any(densite <= 0) || any(isnan(densite))
        v = Inf;
        return;
    end
    v = -sum(log(densite));
end
