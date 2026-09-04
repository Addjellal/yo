function [entrees, sorties] = matlibre_reseau_bornes(reseau)
%MATLIBRE_RESEAU_BORNES Couches d'entrée et de sortie d'un réseau.
%   [E,S] = MATLIBRE_RESEAU_BORNES(RESEAU) rend le nom des couches que
%   rien n'alimente et celui des couches qui n'alimentent rien.
%
%   Exemple :
%      net = dlnetwork({featureInputLayer(2), softmaxLayer()});
%      net.InputNames{1}
%
%   Voir aussi DLNETWORK, LAYERGRAPH.
    noms = reseau.Names;
    alimentees = false(1, numel(noms));
    alimentent = false(1, numel(noms));
    connexions = reseau.Connections;
    for k = 1:height(connexions)
        alimentent(strcmp(noms, connexions.Source{k})) = true;
        alimentees(strcmp(noms, connexions.Destination{k})) = true;
    end
    entrees = noms(~alimentees);
    sorties = noms(~alimentent);
end
