function comet3(x, y, z, queue)
%COMET3 Trace une courbe de l'espace comme si elle se dessinait.
%   COMET3(X,Y,Z) fait ce que fait COMET, pour une courbe de l'espace.
%   COMET3(Z) place les points aux indices.
%   COMET3(X,Y,Z,P) donne à la traînée la longueur P.
%
%   Le rendu de MatLibre est plan : la courbe est projetée en laissant
%   tomber la troisième coordonnée, comme le fait PLOT3, et l'animation
%   n'est pas jouée — voir COMET.
%
%   Exemples :
%      t = linspace(0, 10*pi, 500);
%      comet3(cos(t), sin(t), t);
%
%   Voir aussi COMET, PLOT3, ANIMATEDLINE.
    if nargin < 3
        z = [];
    end
    if nargin < 4
        queue = 0.1;
    end
    if nargin == 1
        y = x;
        x = 1:numel(y);
    end
    comet(x, y, queue);
end
