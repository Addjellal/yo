function sortie = matlibre_reseau_sorties(sorties, etat, nombre)
%MATLIBRE_RESEAU_SORTIES Arguments de sortie d'un passage avant.
%   S = MATLIBRE_RESEAU_SORTIES(SORTIES,ETAT,NOMBRE) rend les sorties
%   demandées, suivies de l'état quand le réseau n'a qu'une sortie et
%   qu'on en demande deux — c'est la convention de MATLAB.
%
%   Exemple :
%      s = matlibre_reseau_sorties({1}, [], 2);
%
%   Voir aussi DLNETWORK, FORWARD, PREDICT.
    nombre = max(nombre, 1);
    if numel(sorties) == 1 && nombre >= 2
        sortie = [sorties, {etat}];
        sortie = sortie(1:min(nombre, 2));
        return
    end
    sortie = sorties(1:min(nombre, numel(sorties)));
end
