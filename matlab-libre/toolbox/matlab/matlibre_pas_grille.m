function pas = matlibre_pas_grille(x, y)
%MATLIBRE_PAS_GRILLE La distance typique entre deux points voisins.
%   Fonction interne : elle n'existe pas dans MATLAB. QUIVER s'en sert
%   pour mettre les flèches à l'échelle, de sorte que la plus longue
%   tienne dans une maille sans empiéter sur la voisine.
    x = x(:);
    y = y(:);
    distinctsX = unique(x);
    distinctsY = unique(y);
    pasX = Inf;
    pasY = Inf;
    if numel(distinctsX) > 1
        pasX = min(diff(distinctsX));
    end
    if numel(distinctsY) > 1
        pasY = min(diff(distinctsY));
    end
    pas = min(pasX, pasY);
    if ~isfinite(pas) || pas <= 0
        etendue = max(max(x) - min(x), max(y) - min(y));
        if etendue > 0
            pas = etendue / max(1, sqrt(numel(x)));
        else
            pas = 1;
        end
    end
end
