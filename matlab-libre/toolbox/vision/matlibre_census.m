function C = matlibre_census(I, taille)
%MATLIBRE_CENSUS Transformée de recensement d'une image.
%   C = MATLIBRE_CENSUS(I,TAILLE) rend, pour chaque pixel, le tableau des
%   comparaisons « ce voisin est-il plus clair que moi ». C est un tableau
%   à trois dimensions : un plan logique par voisin de la fenêtre.
%
%   Ce codage ne retient que l'ordre des intensités, pas leur valeur : il
%   est donc insensible à un changement d'éclairage entre deux prises de
%   vue, ce qui en fait la mesure de ressemblance habituelle en
%   stéréovision.
%
%   Exemple :
%      C = matlibre_census(magic(6), 3);
%      size(C)    % 6 6 8
%
%   Voir aussi DISPARITYSGM, DISPARITYBM.
    I = double(I);
    rayon = max(1, floor(taille / 2));
    [h, l] = size(I);
    etendue = padarray(I, [rayon rayon], 'replicate');
    voisins = (2 * rayon + 1) ^ 2 - 1;
    C = false(h, l, voisins);
    plan = 0;
    for di = -rayon:rayon
        for dj = -rayon:rayon
            if di == 0 && dj == 0
                continue
            end
            plan = plan + 1;
            decale = etendue((1:h) + rayon + di, (1:l) + rayon + dj);
            C(:, :, plan) = decale > I;
        end
    end
end
