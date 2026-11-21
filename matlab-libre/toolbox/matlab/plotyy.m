function [axes_, H1, H2] = plotyy(x1, y1, x2, y2, fonction1, fonction2)
%PLOTYY Deux courbes, deux échelles d'ordonnées.
%   PLOTYY(X1,Y1,X2,Y2) trace la première courbe sur l'échelle de gauche
%   et la seconde sur une échelle qui lui est propre, graduée à droite,
%   chacune de sa couleur — la première couleur de MATLAB à gauche, la
%   deuxième à droite —, comme YYAXIS.
%
%   PLOTYY(X1,Y1,X2,Y2,F) emploie la fonction de tracé nommée F —
%   'plot', 'semilogy', 'stem'… — pour les deux courbes.
%   PLOTYY(X1,Y1,X2,Y2,F1,F2) en emploie une pour chacune.
%
%   [AX,H1,H2] = PLOTYY(...) rend les deux axes — AX(1) vise la gauche,
%   AX(2) la droite : ylabel(AX(2),...) et ylim(AX(2),...) règlent
%   l'échelle de droite — et les poignées des deux courbes.
%
%   Depuis R2016a, MATLAB recommande YYAXIS plutôt que PLOTYY.
%
%   Exemples :
%      x = 0:0.1:10;
%      [ax, h1, h2] = plotyy(x, sin(x), x, 1000 * exp(-x));
%      ylabel(ax(1), 'sin'); ylabel(ax(2), 'exp');
%
%   Voir aussi PLOT, YYAXIS, SUBPLOT, LEGEND, TILEDLAYOUT.
    if nargin < 5 || isempty(fonction1)
        fonction1 = 'plot';
    end
    if nargin < 6 || isempty(fonction2)
        fonction2 = fonction1;
    end
    if ~ishold()
        cla;
    end
    tracer1 = str2func(char(fonction1));
    tracer2 = str2func(char(fonction2));
    yyaxis('left');
    H1 = tracer1(x1, y1);
    yyaxis('right');
    H2 = tracer2(x2, y2);
    yyaxis('left');
    ax = gca();
    axes_ = [matlibre_cote_axe(ax, 0), matlibre_cote_axe(ax, 1)];
end
