function sgrid(zeta, wn)
%SGRID Grille d'amortissement et de pulsation propre, plan continu.
%   SGRID trace, sur la figure courante, les droites d'amortissement
%   constant et les arcs de pulsation propre constante du plan de Laplace.
%   C'est la grille que l'on lit sur un lieu des racines ou une carte des
%   pôles : un pôle sur la droite à 0.7 donne un dépassement de cinq pour
%   cent, un pôle sur l'arc à 10 rad/s une réponse de l'ordre de la demi-
%   seconde.
%
%   SGRID(ZETA,WN) ne trace que les valeurs demandées.
%
%   Les bornes de l'axe ne bougent pas : la grille s'y adapte.
%
%   Exemples :
%      figure
%      rlocus(tf(1, [1 2 0]));
%      sgrid
%      close
%      figure
%      pzmap(tf(1, [1 0.4 1]));
%      sgrid(0.2, 1);
%      close
%
%   Voir aussi ZGRID, NGRID, RLOCUS, PZMAP, DAMP.
    if nargin < 1 || isempty(zeta)
        zeta = [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9];
    end
    bornesX = xlim();
    bornesY = ylim();
    if nargin < 2 || isempty(wn)
        rayonMax = max(abs([bornesX, bornesY]));
        wn = rayonMax * (0.2:0.2:1);
    end
    tenu = ishold();
    hold on;
    % Les droites d'amortissement constant : deux rayons par valeur.
    rayon = max(abs([bornesX, bornesY])) * 1.5;
    for k = 1:numel(zeta)
        z = min(max(zeta(k), 0), 1);
        angle = acos(z);
        x = -rayon * cos(angle);
        y = rayon * sin(angle);
        plot([0 x], [0 y], ':', 'Color', '#B0B0B0');
        plot([0 x], [0 -y], ':', 'Color', '#B0B0B0');
    end
    % Les arcs de pulsation propre constante, dans le demi-plan gauche.
    theta = linspace(pi/2, 3*pi/2, 60);
    for k = 1:numel(wn)
        if wn(k) <= 0
            continue
        end
        plot(wn(k) * cos(theta), wn(k) * sin(theta), ':', 'Color', '#B0B0B0');
    end
    % La grille ne doit pas etirer l'axe.
    xlim(bornesX);
    ylim(bornesY);
    if ~tenu
        hold off;
    end
end
