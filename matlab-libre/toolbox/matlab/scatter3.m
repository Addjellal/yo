function H = scatter3(x, y, z, varargin)
%SCATTER3 Nuage de points dans l'espace.
%   SCATTER3(X,Y,Z) place un point à chaque triplet.
%   SCATTER3(X,Y,Z,S) donne aux points la taille S.
%   SCATTER3(X,Y,Z,S,C) leur donne la couleur C.
%   SCATTER3(...,STYLE) prend une chaîne de style, comme PLOT.
%
%   H = SCATTER3(...) rend la poignée du nuage.
%
%   Le rendu de MatLibre est plan : les points sont projetés en laissant
%   tomber la troisième coordonnée, comme le fait PLOT3.
%
%   Exemples :
%      scatter3(randn(100,1), randn(100,1), randn(100,1));
%      t = linspace(0, 6*pi, 200);
%      scatter3(cos(t), sin(t), t, 20, 'r');
%
%   Voir aussi SCATTER, PLOT3, STEM3, QUIVER3.
    reste = varargin;
    % La taille et la couleur numeriques ne servent pas au rendu plan de
    % MatLibre : on ne garde que le style, s'il y en a un.
    style = {};
    for k = 1:numel(reste)
        if ischar(reste{k}) || isstring(reste{k})
            style = {char(reste{k})};
            break;
        end
    end
    H = scatter(x, y, style{:});
    if nargout == 0
        clear H;
    end
end
