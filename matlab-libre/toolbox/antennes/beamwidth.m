function largeur = beamwidth(theta, diagramme)
%BEAMWIDTH Ouverture à mi-puissance (-3 dB), en radians.
    p = diagramme .^ 2;
    [maxi, imax] = max(p);
    seuil = maxi / 2;
    gauche = imax;
    while gauche > 1 && p(gauche) > seuil
        gauche = gauche - 1;
    end
    droite = imax;
    while droite < numel(p) && p(droite) > seuil
        droite = droite + 1;
    end
    largeur = theta(droite) - theta(gauche);
end
