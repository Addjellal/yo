function angle = matlibre_orientation_centroide(I, ligne, colonne, rayon)
%MATLIBRE_ORIENTATION_CENTROIDE Direction d'un point d'intérêt.
%   A = MATLIBRE_ORIENTATION_CENTROIDE(I,LIGNE,COLONNE,RAYON) rend l'angle
%   du vecteur qui va du pixel au centre de masse des intensités de son
%   disque de rayon RAYON. Cette direction tourne avec l'image : c'est ce
%   qui permet de comparer deux vues d'un même point pris sous des angles
%   différents.
%
%   Exemple :
%      I = zeros(31); I(16, 20:31) = 1;
%      matlibre_orientation_centroide(I, 16, 16, 10)     % environ 0
%
%   Voir aussi DETECTORBFEATURES.
    [h, l] = size(I);
    lignes = max(1, ligne - rayon):min(h, ligne + rayon);
    colonnes = max(1, colonne - rayon):min(l, colonne + rayon);
    bloc = I(lignes, colonnes);
    [X, Y] = meshgrid(colonnes - colonne, lignes - ligne);
    dedans = (X .^ 2 + Y .^ 2) <= rayon ^ 2;
    poids = bloc .* dedans;
    m10 = sum(sum(poids .* X));
    m01 = sum(sum(poids .* Y));
    angle = atan2(m01, m10);
end
