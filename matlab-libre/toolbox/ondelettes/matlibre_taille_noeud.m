function taille = matlibre_taille_noeud(arbre, indice)
%MATLIBRE_TAILLE_NOEUD Taille des données d'un nœud d'arbre de paquets.
%   Sert à la reconstruction : IDWT et IDWT2 reçoivent la taille du
%   parent, que les enfants ne laissent pas déduire hors du mode 'per'.
%   Rend la longueur (arbre de signal) ou la taille (arbre d'image), ou
%   un vide si le nœud n'a pas de données.
    donnees = lireNoeud(arbre, indice);
    if isempty(donnees) && indice == 0
        if arbre.dimension == 1
            taille = arbre.longueur;
        else
            taille = arbre.taille;
        end
        return
    end
    if isempty(donnees)
        taille = [];
    elseif arbre.dimension == 1
        taille = numel(donnees);
    else
        taille = [size(donnees, 1), size(donnees, 2)];
    end
end
