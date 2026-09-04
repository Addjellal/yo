function t = matlibre_reseau_table_vide()
%MATLIBRE_RESEAU_TABLE_VIDE Table de paramètres sans aucune ligne.
%   T = MATLIBRE_RESEAU_TABLE_VIDE() rend la table à trois colonnes —
%   couche, paramètre, valeur — que portent les propriétés Learnables et
%   State d'un DLNETWORK.
%
%   Exemple :
%      height(matlibre_reseau_table_vide())      % 0
%
%   Voir aussi DLNETWORK.
    t = table(cell(0, 1), cell(0, 1), cell(0, 1), ...
              'VariableNames', {'Layer', 'Parameter', 'Value'});
end
