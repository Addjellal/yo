function taille = matlibre_taille_glissante(entree, noyau, pas, bords, dilatation)
%MATLIBRE_TAILLE_GLISSANTE Taille produite par un filtre glissant.
%   T = MATLIBRE_TAILLE_GLISSANTE(ENTREE,NOYAU,PAS,BORDS,DILATATION) rend
%   le nombre de positions que prend le filtre dans chaque dimension.
%
%   Exemple :
%      matlibre_taille_glissante([5 5], [3 3], [1 1], [0 0 0 0], [1 1])   % 3 3
%
%   Voir aussi DLCONV, MAXPOOL, MATLIBRE_COUCHE_INITIALISER.
    etendue = [entree(1) + bords(1) + bords(2), entree(2) + bords(3) + bords(4)];
    taille = floor((etendue - (noyau - 1) .* dilatation - 1) ./ pas) + 1;
end
