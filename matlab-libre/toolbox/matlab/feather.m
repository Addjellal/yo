function H = feather(u, v, style)
%FEATHER Flèches réparties le long de l'axe des abscisses.
%   FEATHER(U,V) trace la k-ième flèche à partir du point (k,0). C'est le
%   diagramme des vents en météorologie : il montre comment un vecteur
%   tourne au fil du temps.
%
%   FEATHER(Z) où Z est complexe emploie la partie réelle et la partie
%   imaginaire.
%
%   FEATHER(...,STYLE) prend une chaîne de style.
%
%   H = FEATHER(...) rend les poignées.
%
%   Exemples :
%      t = 0:pi/8:2*pi;
%      feather(cos(t), sin(t));           % le vecteur fait un tour
%      feather(exp(1i * t) .* (1:numel(t)) / 10);
%
%   Voir aussi COMPASS, QUIVER, POLARPLOT, PLOT.
    if nargin < 2 || (nargin >= 2 && (ischar(v) || isstring(v)))
        if nargin >= 2
            style = v;
        end
        v = imag(u);
        u = real(u);
    end
    if ~exist('style', 'var') || isempty(style)
        style = 'b';
    end
    u = u(:);
    v = v(:);
    n = numel(u);
    aEffacer = ishold();
    if ~aEffacer
        cla;
    end
    hold('on');
    H = plot([0.5, n + 0.5], [0 0], 'Color', [0.7 0.7 0.7]);
    echelle = 0.15 * max(max(abs(u)), max(abs(v)));
    for k = 1:n
        [tx, ty] = matlibre_fleche(k, 0, u(k), v(k), echelle);
        H(end + 1) = plot(tx, ty, style);      %#ok<AGROW>
    end
    if ~aEffacer
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end
