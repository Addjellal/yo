function S = matlibre_produit_vectoriel_matrice(v)
%MATLIBRE_PRODUIT_VECTORIEL_MATRICE Matrice antisymétrique d'un vecteur.
%   S = MATLIBRE_PRODUIT_VECTORIEL_MATRICE(V) rend la matrice telle que
%   S*W soit le produit vectoriel de V et de W, quel que soit W.
%
%   Exemple :
%      S = matlibre_produit_vectoriel_matrice([0 0 1]);
%      S * [1; 0; 0]      % 0 1 0
%
%   Voir aussi ESTIMATEUNCALIBRATEDRECTIFICATION, CROSS.
    v = v(:);
    S = [0 -v(3) v(2); v(3) 0 -v(1); -v(2) v(1) 0];
end
