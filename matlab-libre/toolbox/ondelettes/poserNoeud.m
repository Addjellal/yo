function arbre = poserNoeud(arbre, indice, donnees)
%POSERNOEUD Range les coefficients d'un nœud dans l'arbre.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      arbre = wpdec(sin((1:64) / 5), 1, 'haar');
%      arbre = poserNoeud(arbre, 500, [1 2 3]);
%      lireNoeud(arbre, 500)       % 1 2 3
%
%   Voir aussi LIRENOEUD, INDICEDENOEUD, SCINDERNOEUD.
    if indice + 1 > numel(arbre.donnees)
        arbre.donnees{indice + 1} = [];
    end
    arbre.donnees{indice + 1} = donnees;
    if ~any(arbre.noeuds == indice)
        arbre.noeuds = sort([arbre.noeuds, indice]);
    end
end
