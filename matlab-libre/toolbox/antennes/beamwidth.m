function largeur = beamwidth(theta, diagramme)
%BEAMWIDTH Ouverture à mi-puissance (-3 dB), en radians.
%   LARGEUR = BEAMWIDTH(THETA,DIAGRAMME) rend l'écart angulaire entre les
%   deux points où la puissance tombe à la moitié du maximum, de part et
%   d'autre de celui-ci. DIAGRAMME est en amplitude, non en puissance.
%
%   L'ouverture varie comme l'inverse de la longueur totale d'un réseau,
%   non comme l'inverse du nombre d'éléments : doubler la longueur divise
%   l'ouverture par deux. C'est la résolution angulaire, et elle ne
%   s'achète qu'en étendue physique.
%
%   La mesure se fait sur l'échantillonnage fourni : un maillage trop
%   grossier la surestime.
%
%   Exemple :
%      theta = linspace(1e-6, pi - 1e-6, 20001);
%      rad2deg(beamwidth(theta, dipolePattern(theta, 0.5)))   % 78
%
%   Voir aussi DIRECTIVITY, DIPOLEPATTERN, ARRAYFACTOR.
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
