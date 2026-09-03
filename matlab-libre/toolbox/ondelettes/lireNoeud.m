function donnees = lireNoeud(arbre, indice)
%LIRENOEUD Coefficients d'un nœud, vides s'il n'est pas dans l'arbre.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if indice + 1 > numel(arbre.donnees) || ~any(arbre.noeuds == indice)
        donnees = [];
    else
        donnees = arbre.donnees{indice + 1};
    end
end
