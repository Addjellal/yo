function [x, y] = matlibre_fleche(x0, y0, dx, dy, taille)
%MATLIBRE_FLECHE Le tracé d'une flèche, hampe et pointe d'un seul trait.
%   Fonction interne : elle n'existe pas dans MATLAB. QUIVER, COMPASS et
%   FEATHER s'en servent ; la flèche est rendue comme une seule polyligne,
%   ce qui la fait tenir en une courbe et non en trois.
    longueur = sqrt(dx ^ 2 + dy ^ 2);
    x = [x0, x0 + dx];
    y = [y0, y0 + dy];
    if longueur == 0 || taille <= 0
        return;
    end
    taille = min(taille, longueur * 0.4);
    ux = dx / longueur;
    uy = dy / longueur;
    % Les deux barbes, a trente degres de la hampe.
    angle = pi / 7;
    for signe = [1, -1]
        bx = -ux * cos(angle) + signe * uy * sin(angle);
        by = -uy * cos(angle) - signe * ux * sin(angle);
        x = [x, x0 + dx + taille * bx, x0 + dx];   %#ok<AGROW>
        y = [y, y0 + dy + taille * by, y0 + dy];   %#ok<AGROW>
    end
end
