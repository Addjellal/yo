function donnees = lireNoeud(arbre, indice)
%LIRENOEUD Coefficients d'un nœud, vides s'il n'est pas dans l'arbre.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      arbre = wpdec(sin((1:64) / 5), 1, 'haar');
%      numel(lireNoeud(arbre, 0))      % 64 : la racine porte le signal
%      isempty(lireNoeud(arbre, 999))  % 1 : un noeud absent rend vide
%
%   Voir aussi POSERNOEUD, INDICEDENOEUD, WPCOEF.
    if indice + 1 > numel(arbre.donnees) || ~any(arbre.noeuds == indice)
        donnees = [];
    else
        donnees = arbre.donnees{indice + 1};
    end
end
