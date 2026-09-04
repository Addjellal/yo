function nom = matlibre_reseau_nom_libre(pris, type)
%MATLIBRE_RESEAU_NOM_LIBRE Nom automatique pour une couche anonyme.
%   N = MATLIBRE_RESEAU_NOM_LIBRE(PRIS,TYPE) rend le type suivi du plus
%   petit numéro qui ne soit pas déjà pris, comme le fait MATLAB.
%
%   Exemple :
%      matlibre_reseau_nom_libre({'relu_1'}, 'relu')     % relu_2
%
%   Voir aussi ADDLAYERS, LAYERGRAPH.
    k = 1;
    while true
        nom = sprintf('%s_%d', type, k);
        if ~any(strcmp(pris, nom))
            return
        end
        k = k + 1;
    end
end
