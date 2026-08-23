function y = tripuls(t, w, s)
%TRIPULS Impulsion triangulaire de largeur W et d'asymétrie S.
%   S vaut 0 pour un triangle symétrique, -1 pour une rampe descendante,
%   +1 pour une rampe montante. W vaut 1 et S vaut 0 par défaut.
%
%   Exemple :  tripuls([-0.5 -0.25 0 0.25 0.5])   % [0 0.5 1 0.5 0]
    if nargin < 2 || isempty(w), w = 1; end
    if nargin < 3 || isempty(s), s = 0; end
    if s < -1 || s > 1
        error('signal:tripuls:BadSkew', 'L''asymétrie doit être entre -1 et 1.');
    end
    t = double(t);
    y = zeros(size(t));
    sommet = s * w / 2;
    gauche = t >= -w / 2 & t <= sommet;
    droite = t > sommet & t <= w / 2;
    if sommet > -w / 2
        y(gauche) = (t(gauche) + w / 2) / (sommet + w / 2);
    else
        y(gauche) = 1;
    end
    if sommet < w / 2
        y(droite) = (w / 2 - t(droite)) / (w / 2 - sommet);
    end
end
