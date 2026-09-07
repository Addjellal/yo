function r = matlibre_rayon_circonscrit(sommets)
%MATLIBRE_RAYON_CIRCONSCRIT Rayon du cercle circonscrit d'un triangle.
%   R = abc / 4A, où a, b et c sont les côtés et A l'aire. Un triangle
%   aplati a une aire qui tend vers zéro et donc un rayon qui explose :
%   c'est ce qui permet de reconnaître les triangles étirés et de les
%   retirer d'une forme alpha.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      r = matlibre_rayon_circonscrit([0 0; 1 0; 0 1]);
%      abs(r - sqrt(2)/2) < 1e-12      % le cercle passe par les trois
%
%   Voir aussi BOUNDARY, ALPHASHAPE, CIRCUMCENTER.
    a = norm(sommets(2, :) - sommets(1, :));
    b = norm(sommets(3, :) - sommets(2, :));
    c = norm(sommets(1, :) - sommets(3, :));
    aire = abs((sommets(2, 1) - sommets(1, 1)) * (sommets(3, 2) - sommets(1, 2)) - ...
               (sommets(3, 1) - sommets(1, 1)) * (sommets(2, 2) - sommets(1, 2))) / 2;
    if aire < eps
        r = inf;
    else
        r = a * b * c / (4 * aire);
    end
end
