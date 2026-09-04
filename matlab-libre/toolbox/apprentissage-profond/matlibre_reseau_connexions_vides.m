function t = matlibre_reseau_connexions_vides()
%MATLIBRE_RESEAU_CONNEXIONS_VIDES Table de connexions sans aucune arête.
%   T = MATLIBRE_RESEAU_CONNEXIONS_VIDES() rend la table à deux colonnes,
%   source et destination, que porte un graphe de couches.
%
%   Exemple :
%      height(matlibre_reseau_connexions_vides())      % 0
%
%   Voir aussi LAYERGRAPH, DLNETWORK.
    t = table(cell(0, 1), cell(0, 1), 'VariableNames', {'Source', 'Destination'});
end
