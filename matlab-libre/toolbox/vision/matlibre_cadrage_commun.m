function T = matlibre_cadrage_commun(H1, H2, tailleImage)
%MATLIBRE_CADRAGE_COMMUN Translation qui ramène deux images rectifiées.
%   T = MATLIBRE_CADRAGE_COMMUN(H1,H2,TAILLE) rend la translation qui
%   amène le coin supérieur gauche de la réunion des deux images
%   transformées en (1,1). La même translation est appliquée aux deux, ce
%   qui laisse intact l'alignement des lignes.
%
%   Exemple :
%      T = matlibre_cadrage_commun(eye(3), eye(3), [10 10]);   % identité
%
%   Voir aussi ESTIMATEUNCALIBRATEDRECTIFICATION.
    coins = [1 1; tailleImage(2) 1; tailleImage(2) tailleImage(1); 1 tailleImage(1)];
    tous = [matlibre_appliquer_homographie(H1, coins); ...
            matlibre_appliquer_homographie(H2, coins)];
    T = [1 0 1 - min(tous(:, 1)); 0 1 1 - min(tous(:, 2)); 0 0 1];
end
