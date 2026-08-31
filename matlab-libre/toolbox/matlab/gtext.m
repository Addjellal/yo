function H = gtext(texte, x, y)
%GTEXT Pose un texte sur la figure.
%   GTEXT(TEXTE) place le texte au milieu de l'axe courant.
%   GTEXT(TEXTE,X,Y) le place aux coordonnées données.
%
%   H = GTEXT(...) rend la poignée du texte.
%
%   Dans MATLAB, GTEXT attend que l'on clique pour savoir où poser le
%   texte. MatLibre n'a pas de curseur interactif sur ses figures : sans
%   coordonnées, il pose le texte au centre, et il vaut mieux les lui
%   donner — ou employer TEXT directement.
%
%   Exemples :
%      plot(1:10);
%      gtext('la droite', 5, 5);
%
%   Voir aussi TEXT, TITLE, XLABEL, ANNOTATION, GNAME.
    if nargin < 3
        bornesX = xlim();
        bornesY = ylim();
        x = mean(bornesX);
        y = mean(bornesY);
    end
    if iscell(texte)
        H = [];
        for k = 1:numel(texte)
            H(end + 1) = text(x, y, char(texte{k}));      %#ok<AGROW>
        end
    else
        H = text(x, y, char(texte));
    end
    if nargout == 0
        clear H;
    end
end
