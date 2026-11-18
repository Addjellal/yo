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
%   Les deux points à mi-puissance sont interpolés linéairement entre
%   les échantillons qui les encadrent : l'erreur décroît comme le carré
%   du pas de THETA. S'ils sortent du domaine échantillonné, l'ouverture
%   n'est pas mesurable et BEAMWIDTH le dit.
%
%   Exemple :
%      theta = linspace(1e-6, pi - 1e-6, 20001);
%      rad2deg(beamwidth(theta, dipolePattern(theta, 0.5)))   % 78.08
%
%   Voir aussi DIRECTIVITY, DIPOLEPATTERN, ARRAYFACTOR.
    p = diagramme .^ 2;
    [maxi, imax] = max(p);
    seuil = maxi / 2;
    gauche = find(p(1:imax) <= seuil, 1, 'last');
    droite = imax - 1 + find(p(imax:end) <= seuil, 1, 'first');
    if isempty(gauche) || isempty(droite)
        error('antenna:beamwidth:Domaine', ...
              'Le diagramme ne descend pas à mi-puissance des deux côtés du maximum.');
    end
    largeur = croisement(theta, p, droite - 1, droite, seuil) ...
              - croisement(theta, p, gauche, gauche + 1, seuil);
end

function t = croisement(theta, p, i, j, seuil)
    if p(j) == p(i)
        t = theta(i);
    else
        t = theta(i) + (seuil - p(i)) * (theta(j) - theta(i)) / (p(j) - p(i));
    end
end
