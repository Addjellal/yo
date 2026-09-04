function valeurs = matlibre_reseau_lire(tableau, nom)
%MATLIBRE_RESEAU_LIRE Paramètres d'une couche, en structure.
%   V = MATLIBRE_RESEAU_LIRE(TABLEAU,NOM) extrait de la table des
%   paramètres ceux de la couche nommée, sous la forme d'une structure
%   dont les champs portent le nom du paramètre.
%
%   Exemple :
%      v = matlibre_reseau_lire(net.Learnables, 'fc_1');
%      size(v.Weights)
%
%   Voir aussi DLNETWORK, MATLIBRE_RESEAU_ECRIRE.
    valeurs = struct();
    if isempty(tableau) || height(tableau) == 0
        return
    end
    lignes = find(strcmp(tableau.Layer, nom));
    for k = 1:numel(lignes)
        valeurs.(tableau.Parameter{lignes(k)}) = tableau.Value{lignes(k)};
    end
end
