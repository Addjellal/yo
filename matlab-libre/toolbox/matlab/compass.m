function H = compass(u, v, style)
%COMPASS Flèches partant de l'origine.
%   COMPASS(U,V) trace, pour chaque couple (U,V), une flèche qui part de
%   l'origine et va au point. C'est la rose des vents : elle montre d'un
%   coup où pointent des vecteurs et de quelle longueur ils sont.
%
%   COMPASS(Z) où Z est complexe emploie la partie réelle et la partie
%   imaginaire.
%
%   COMPASS(...,STYLE) prend une chaîne de style, comme PLOT.
%
%   H = COMPASS(...) rend les poignées.
%
%   Exemples :
%      compass([1 2 -1], [2 1 1]);
%      compass(exp(1i * (0:pi/6:2*pi)));      % les douze directions
%
%   Voir aussi FEATHER, QUIVER, POLARPLOT, ROSE, PLOT.
    if nargin < 2 || (nargin >= 2 && (ischar(v) || isstring(v)))
        if nargin >= 2
            style = v;
        end
        v = imag(u);
        u = real(u);
    end
    if nargin < 3 && ~exist('style', 'var')
        style = 'b';
    end
    if isempty(style)
        style = 'b';
    end
    u = u(:);
    v = v(:);
    rayons = sqrt(u .^ 2 + v .^ 2);
    aEffacer = ishold();
    if ~aEffacer
        cla;
        matlibre_grille_polaire(max(rayons));
    end
    hold('on');
    H = [];
    for k = 1:numel(u)
        [tx, ty] = matlibre_fleche(0, 0, u(k), v(k), 0.12 * max(rayons));
        H(end + 1) = plot(tx, ty, style);      %#ok<AGROW>
    end
    if ~aEffacer
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end
