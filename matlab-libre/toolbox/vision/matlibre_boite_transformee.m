function boite = matlibre_boite_transformee(T, tailleImage)
%MATLIBRE_BOITE_TRANSFORMEE Rectangle occupé par une image transformée.
%   B = MATLIBRE_BOITE_TRANSFORMEE(T,TAILLE) rend [xmin ymin xmax ymax],
%   l'enveloppe des quatre coins de l'image une fois transformée par T.
%
%   Exemple :
%      matlibre_boite_transformee(eye(3), [4 5])   % 1 1 5 4
%
%   Voir aussi RECTIFYSTEREOIMAGES, MATLIBRE_PROJETER_IMAGE.
    coins = [1 1; tailleImage(2) 1; tailleImage(2) tailleImage(1); 1 tailleImage(1)];
    projetes = matlibre_appliquer_homographie(double(T).', coins);
    boite = [min(projetes(:, 1)), min(projetes(:, 2)), ...
             max(projetes(:, 1)), max(projetes(:, 2))];
end
