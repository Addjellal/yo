function [P, E] = phantom(def, n)
%PHANTOM Fantôme de Shepp et Logan, ou image d'ellipses.
%   P = PHANTOM(N) rend le fantôme de tête de Shepp et Logan modifié (Toft,
%   1996) sur une grille N x N (256 par défaut), comme MATLAB : dix
%   ellipses dont les densités s'ajoutent.
%   P = PHANTOM(DEF,N) choisit le fantôme : 'Modified Shepp-Logan'
%   (défaut, contrastes relevés pour l'affichage) ou 'Shepp-Logan'
%   (l'original de 1974) ; DEF peut aussi être une matrice d'ellipses, une
%   ligne [A a b x0 y0 phi] par ellipse : densité, demi-axes, centre et
%   angle en degrés, sur le carré [-1,1] x [-1,1].
%   [P,E] = PHANTOM(...) rend aussi la matrice des ellipses.
%
%   Exemple :
%      P = phantom(128);
%      [max(P(:)) min(P(:))]           % 1 et 0
%
%   Voir aussi RADON, IRADON.
    if nargin < 2, n = 256; end
    if nargin < 1, def = 'Modified Shepp-Logan'; end
    if nargin == 1 && isnumeric(def) && isscalar(def)
        n = def;
        def = 'Modified Shepp-Logan';
    end
    if ischar(def) || isstring(def)
        switch lower(char(def))
            case 'modified shepp-logan'
                E = ellipses([1 -0.8 -0.2 -0.2 0.1 0.1 0.1 0.1 0.1 0.1]);
            case 'shepp-logan'
                E = ellipses([2 -0.98 -0.02 -0.02 0.01 0.01 0.01 0.01 0.01 0.01]);
            otherwise
                error('images:phantom:unknownPhantom', ...
                      'Fantôme inconnu : ''Modified Shepp-Logan'' ou ''Shepp-Logan''.');
        end
    else
        E = def;
        if size(E, 2) ~= 6
            error('images:phantom:invalidEllipseMatrix', ...
                  'Une ellipse par ligne : [A a b x0 y0 phi].');
        end
    end
    axe = ((0:n - 1) - (n - 1) / 2) / ((n - 1) / 2);
    xg = repmat(axe, n, 1);
    yg = rot90(xg);
    P = zeros(n);
    for k = 1:size(E, 1)
        A = E(k, 1); a = E(k, 2); b = E(k, 3);
        x = xg - E(k, 4);
        y = yg - E(k, 5);
        phi = E(k, 6) * pi / 180;
        dedans = ((x * cos(phi) + y * sin(phi)) .^ 2) / a ^ 2 + ...
                 ((y * cos(phi) - x * sin(phi)) .^ 2) / b ^ 2 <= 1;
        P(dedans) = P(dedans) + A;
    end
end

function E = ellipses(densites)
%ELLIPSES La géométrie du fantôme de Shepp et Logan, avec ces densités.
    E = [0.69 0.92 0 0 0; 0.6624 0.874 0 -0.0184 0; 0.11 0.31 0.22 0 -18;
         0.16 0.41 -0.22 0 18; 0.21 0.25 0 0.35 0; 0.046 0.046 0 0.1 0;
         0.046 0.046 0 -0.1 0; 0.046 0.023 -0.08 -0.605 0; 0.023 0.023 0 -0.606 0;
         0.023 0.046 0.06 -0.605 0];
    E = [densites(:), E];
end
