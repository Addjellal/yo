function arbre = poserNoeud(arbre, indice, donnees)
%POSERNOEUD Range les coefficients d'un nœud dans l'arbre.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if indice + 1 > numel(arbre.donnees)
        arbre.donnees{indice + 1} = [];
    end
    arbre.donnees{indice + 1} = donnees;
    if ~any(arbre.noeuds == indice)
        arbre.noeuds = sort([arbre.noeuds, indice]);
    end
end
