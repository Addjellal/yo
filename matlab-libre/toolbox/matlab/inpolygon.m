function [dedans, sur] = inpolygon(xq, yq, xv, yv)
%INPOLYGON Points intérieurs à un polygone.
%   IN = INPOLYGON(XQ,YQ,XV,YV) vaut vrai pour les points de (XQ,YQ) qui
%   sont dans le polygone de sommets (XV,YV), bord compris.
%
%   [IN,ON] = INPOLYGON(...) distingue les points posés sur le bord.
%
%   Le test est celui du nombre de traversées : on compte les côtés que
%   coupe une demi-droite partant du point ; un nombre impair signifie
%   que le point est dedans.
%
%   Exemple :
%      inpolygon(0.5, 0.5, [0 1 1 0], [0 0 1 1])   % vrai
    xq = double(xq);
    yq = double(yq);
    xv = double(xv(:));
    yv = double(yv(:));
    % Le polygone est fermé implicitement.
    if xv(1) ~= xv(end) || yv(1) ~= yv(end)
        xv(end + 1) = xv(1);
        yv(end + 1) = yv(1);
    end
    % Le test est mené côté par côté, mais sur tous les points à la
    % fois : c'est le seul moyen de rester rapide dans un interpréteur.
    traversees = false(size(xq));
    sur = false(size(xq));
    n = numel(xv) - 1;
    for c = 1:n
        x1 = xv(c); y1 = yv(c);
        x2 = xv(c + 1); y2 = yv(c + 1);
        aire = (x2 - x1) * (yq - y1) - (y2 - y1) * (xq - x1);
        longueur = hypot(x2 - x1, y2 - y1);
        if longueur > 0
            borde = abs(aire) <= 1e-12 * max(1, longueur) & ...
                    xq >= min(x1, x2) - 1e-12 & xq <= max(x1, x2) + 1e-12 & ...
                    yq >= min(y1, y2) - 1e-12 & yq <= max(y1, y2) + 1e-12;
            sur = sur | borde;
        end
        if y1 ~= y2
            enface = (y1 > yq) ~= (y2 > yq);
            abscisse = x1 + (yq - y1) / (y2 - y1) * (x2 - x1);
            traversees = xor(traversees, enface & (xq < abscisse));
        end
    end
    dedans = traversees | sur;
end
