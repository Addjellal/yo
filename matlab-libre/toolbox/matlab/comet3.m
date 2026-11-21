function comet3(x, y, z, queue)
%COMET3 Trace une courbe de l'espace comme si elle se dessinait.
%   COMET3(X,Y,Z) fait ce que fait COMET, pour une courbe de l'espace.
%   COMET3(Z) place les points aux indices.
%   COMET3(X,Y,Z,P) donne à la traînée la longueur P.
%
%   L'animation n'est pas jouée — voir COMET : la courbe est montrée dans
%   son état final, en perspective, sa queue appuyée et sa tête marquée.
%
%   Exemples :
%      t = linspace(0, 10*pi, 500);
%      comet3(cos(t), sin(t), t);
%
%   Voir aussi COMET, PLOT3, ANIMATEDLINE.
    if nargin < 4 || isempty(queue)
        queue = 0.1;
    end
    if nargin == 1
        z = x;
        x = 1:numel(z);
        y = x;
    elseif nargin < 3 || isempty(z)
        comet(x, y, queue);
        return
    end
    x = x(:);
    y = y(:);
    z = z(:);
    n = numel(x);
    debutQueue = max(1, n - round(queue * n));
    tenu = ishold();
    plot3(x, y, z, 'Color', [0.6 0.6 0.85]);
    hold('on');
    plot3(x(debutQueue:end), y(debutQueue:end), z(debutQueue:end), 'b', 'LineWidth', 2);
    plot3(x(end), y(end), z(end), 'ro', 'LineWidth', 2);
    if ~tenu
        hold('off');
    end
end
