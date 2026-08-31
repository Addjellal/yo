function comet(x, y, queue)
%COMET Trace une courbe comme si elle se dessinait.
%   COMET(Y) trace Y point à point ; COMET(X,Y) place les points en X.
%   COMET(X,Y,P) donne à la traînée la longueur P, en fraction de la
%   courbe ; 0.1 par défaut.
%
%   Dans MATLAB, l'animation se voit : la tête avance et la traînée la
%   suit. MatLibre n'anime pas ses figures — elles sont rendues une fois
%   pour toutes — et COMET dessine donc la courbe entière, avec sa
%   dernière traînée en évidence et un point à la tête. Ce que l'on garde
%   d'une animation quand on l'imprime, c'est exactement cela.
%
%   Exemples :
%      t = linspace(0, 10*pi, 500);
%      comet(t .* cos(t), t .* sin(t));
%
%   Voir aussi COMET3, PLOT, ANIMATEDLINE, DRAWNOW.
    if nargin < 2 || isempty(y)
        y = x;
        x = 1:numel(y);
    end
    if nargin < 3 || isempty(queue)
        queue = 0.1;
    end
    x = x(:);
    y = y(:);
    n = numel(x);
    debutQueue = max(1, n - round(queue * n));
    aEffacer = ishold();
    if ~aEffacer
        cla;
    end
    hold('on');
    plot(x, y, 'Color', [0.6 0.6 0.85]);
    plot(x(debutQueue:end), y(debutQueue:end), 'b', 'LineWidth', 2);
    plot(x(end), y(end), 'ro', 'LineWidth', 2);
    if ~aEffacer
        hold('off');
    end
end
