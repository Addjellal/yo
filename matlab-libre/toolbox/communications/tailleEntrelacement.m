function n = tailleEntrelacement(donnees)
%TAILLEENTRELACEMENT Nombre d'éléments qu'un entrelaceur doit permuter.
%   Pour un vecteur c'est sa longueur, pour une matrice son nombre de
%   lignes : les colonnes sont entrelacées de la même façon.
    if isvector(donnees)
        n = numel(donnees);
    else
        n = size(donnees, 1);
    end
end
