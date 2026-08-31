function H = lsline()
%LSLINE Ajoute la droite des moindres carrés à un nuage de points.
%   LSLINE ajuste une droite par moindres carrés sur les points déjà
%   tracés dans l'axe courant, et l'ajoute au dessin. C'est REFLINE sans
%   argument, sous le nom que MATLAB lui donne aussi.
%
%   H = LSLINE rend la poignée de la droite.
%
%   Exemples :
%      x = 1:20;
%      plot(x, 2 * x + randn(1, 20) * 2, 'o');
%      lsline;
%
%   Voir aussi REFLINE, REFCURVE, POLYFIT, REGRESS.
    H = refline();
    if nargout == 0
        clear H;
    end
end
