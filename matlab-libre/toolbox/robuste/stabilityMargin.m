function [margeModule, margeRetard] = stabilityMargin(sys)
%STABILITYMARGIN Marge de module et marge de retard.
%   [MM,MR] = STABILITYMARGIN(SYS) rend deux mesures de robustesse d'une
%   boucle ouverte : la marge de module, distance minimale du lieu de
%   Nyquist au point critique -1, et la marge de retard, retard pur que
%   la boucle supporte avant de devenir instable.
%
%   La marge de module vaut l'inverse du pic de la sensibilité : une
%   marge de 0.5 dit qu'aucune perturbation multiplicative inférieure à
%   la moitié du gain ne peut déstabiliser la boucle. Elle résume à elle
%   seule les marges de gain et de phase.
%
%   Exemples :
%      [mm, mr] = stabilityMargin(tf(1, [1 1 0]));
%      mm > 0 && mm < 1                     % la marge de module
%      mr > 0                               % le retard admissible, en secondes
%
%   Voir aussi MARGIN, ALLMARGIN, NYQUIST, HINFNORM.
    w = logspace(-4, 4, 8000).';
    [m, p] = bode(sys, w);
    h = m .* exp(1i * p * pi / 180);
    margeModule = min(abs(h + 1));
    [~, pm, ~, wc] = margin(sys);
    if isfinite(pm) && isfinite(wc) && wc > 0
        margeRetard = (pm * pi / 180) / wc;
    else
        margeRetard = inf;
    end
end
