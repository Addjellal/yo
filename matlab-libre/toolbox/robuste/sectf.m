function [Gt, T] = sectf(G, secteurEntree, secteurSortie)
%SECTF Transformation de secteur.
%   GT = SECTF(G,[A B]) transforme G de sorte qu'une non-linéarité
%   comprise dans le secteur [A,B] devienne une non-linéarité comprise
%   dans le secteur [-1,1]. C'est la transformation de boucle qui ramène
%   un problème de stabilité absolue à une condition de petit gain.
%
%   Une non-linéarité du secteur [A,B] s'écrit phi = c + r*psi avec
%   c = (A+B)/2, r = (B-A)/2 et psi dans [-1,1]. En reportant dans la
%   boucle y = G u, u = -phi(y), il vient
%
%      GT = r * (I + c*G)^-1 * G
%
%   C'est un déplacement de boucle, non une simple soustraction : le
%   terme constant du secteur se referme sur le procédé.
%
%   GT = SECTF(G,[A B],[C D]) transforme aussi le secteur de sortie.
%
%   [GT,T] = SECTF(...) rend en outre les paramètres employés.
%
%   Le critère du cercle dit qu'une boucle formée de G et d'une
%   non-linéarité du secteur [A,B] est stable si le lieu de Nyquist de G
%   évite le disque construit sur -1/A et -1/B. Après SECTF, la même
%   condition s'écrit simplement : la norme infinie de GT est inférieure
%   à un.
%
%   Exemples :
%      G = ss(tf(1, [1 2 1]));
%      Gt = sectf(G, [0 2]);          % une saturation de pente 0 a 2
%      hinfnorm(Gt) < 1               % le critere du cercle est verifie
%
%   Voir aussi POPOV, HINFNORM, NYQUIST, DISKMARGIN.
    G = ss(G);
    a = secteurEntree(1);
    b = secteurEntree(2);
    if b <= a
        error('robust:sectf:BadSector', 'The sector must satisfy A < B.');
    end
    centre = (a + b) / 2;
    rayon = (b - a) / 2;
    ny = size(G.D, 1);
    if centre == 0
        Gt = ss(rayon * G);
    else
        Gt = ss(rayon * feedback(G, centre * ss(eye(ny))));
    end
    T = struct('centre', centre, 'rayon', rayon);
    if nargin >= 3 && ~isempty(secteurSortie)
        c = secteurSortie(1);
        d = secteurSortie(2);
        centreSortie = (c + d) / 2;
        rayonSortie = (d - c) / 2;
        if centreSortie ~= 0
            Gt = ss(feedback(Gt, centreSortie * ss(eye(size(Gt.D, 1)))));
        end
        Gt = ss(rayonSortie * Gt);
        T.centreSortie = centreSortie;
        T.rayonSortie = rayonSortie;
    end
end
