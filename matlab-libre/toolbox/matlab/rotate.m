function rotate(poignees, direction, angle, origine)
%ROTATE Fait tourner des objets graphiques.
%   ROTATE(H,DIRECTION,ANGLE) fait tourner les objets désignés par H de
%   ANGLE degrés autour de l'axe DIRECTION, qui est donné soit par
%   [AZIMUT ELEVATION], soit par un vecteur [X Y Z].
%
%   ROTATE(H,DIRECTION,ANGLE,ORIGINE) fait passer l'axe par ORIGINE
%   plutôt que par le centre du tracé.
%
%   MatLibre applique la rotation dans le plan des X et des Y, la seule
%   que son rendu montre : une rotation autour de l'axe des Z tourne
%   comme dans MATLAB, les autres ne changent rien.
%
%   Exemples :
%      h = plot([0 1], [0 0], 'LineWidth', 2);
%      rotate(h, [0 0 1], 90);        % la ligne se dresse
%
%   Voir aussi ROTATE3D, VIEW, SET, GET.
    if nargin < 4 || isempty(origine)
        origine = [];
    end
    if numel(direction) == 2
        % [azimut elevation] : l'axe pointe dans cette direction.
        azimut = direction(1) * pi / 180;
        elevation = direction(2) * pi / 180;
        axe = [cos(elevation) * cos(azimut), cos(elevation) * sin(azimut), ...
               sin(elevation)];
    else
        axe = direction(:)';
        if numel(axe) < 3
            axe(3) = 0;
        end
    end
    % Seule la composante selon z fait tourner le plan du dessin.
    norme = sqrt(sum(axe .^ 2));
    if norme == 0
        return;
    end
    facteur = axe(3) / norme;
    theta = angle * pi / 180 * facteur;
    c = cos(theta);
    s = sin(theta);
    for k = 1:numel(poignees)
        x = get(poignees(k), 'XData');
        y = get(poignees(k), 'YData');
        if isempty(x) || isempty(y)
            continue;
        end
        if isempty(origine)
            centre = [mean(x), mean(y)];
        else
            centre = origine(1:2);
        end
        dx = x(:)' - centre(1);
        dy = y(:)' - centre(2);
        set(poignees(k), 'XData', centre(1) + c * dx - s * dy, ...
                         'YData', centre(2) + s * dx + c * dy);
    end
end
