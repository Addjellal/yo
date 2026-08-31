function [axes_, H1, H2] = plotyy(x1, y1, x2, y2, fonction1, fonction2)
%PLOTYY Deux courbes, deux échelles d'ordonnées.
%   PLOTYY(X1,Y1,X2,Y2) trace la première courbe et la seconde sur le
%   même axe, la seconde étant remise à l'échelle de la première de
%   sorte que les deux occupent la même hauteur. Les graduations de
%   droite, celles de la seconde échelle, sont écrites en légende.
%
%   PLOTYY(X1,Y1,X2,Y2,F) emploie la fonction de tracé nommée F —
%   'plot', 'semilogy', 'stem'… — pour les deux courbes.
%   PLOTYY(X1,Y1,X2,Y2,F1,F2) en emploie une pour chacune.
%
%   [AX,H1,H2] = PLOTYY(...) rend l'axe et les deux poignées.
%
%   MATLAB donne à la seconde courbe un axe des ordonnées qui lui est
%   propre, gradué à droite. MatLibre n'a pas de second axe : il
%   normalise la seconde courbe pour qu'elle se superpose lisiblement à
%   la première, et nomme le facteur dans la légende. La forme des deux
%   courbes et leur comparaison restent justes ; ce sont les graduations
%   de droite qui manquent.
%
%   Depuis R2016a, MATLAB recommande YYAXIS plutôt que PLOTYY.
%
%   Exemples :
%      x = 0:0.1:10;
%      plotyy(x, sin(x), x, 1000 * exp(-x));
%      legend('sin (gauche)', 'exp (droite)');
%
%   Voir aussi PLOT, YYAXIS, SUBPLOT, LEGEND, TILEDLAYOUT.
    if nargin < 5 || isempty(fonction1)
        fonction1 = 'plot';
    end
    if nargin < 6 || isempty(fonction2)
        fonction2 = fonction1;
    end
    aEffacer = ishold();
    if ~aEffacer
        cla;
    end
    tracer1 = str2func(char(fonction1));
    tracer2 = str2func(char(fonction2));
    H1 = tracer1(x1, y1);
    hold('on');
    % La mise a l'echelle : la seconde courbe occupe la meme hauteur que
    % la premiere, et le facteur est dit dans la legende.
    etendue1 = max(y1(:)) - min(y1(:));
    etendue2 = max(y2(:)) - min(y2(:));
    if etendue2 == 0 || etendue1 == 0
        facteur = 1;
        decalage = 0;
    else
        facteur = etendue1 / etendue2;
        decalage = min(y1(:)) - facteur * min(y2(:));
    end
    H2 = tracer2(x2, facteur * y2 + decalage);
    if ~aEffacer
        hold('off');
    end
    if facteur ~= 1 || decalage ~= 0
        ylabel(sprintf('gauche ; droite = (y - %.4g) / %.4g', decalage, facteur));
    end
    axes_ = gca();
end
