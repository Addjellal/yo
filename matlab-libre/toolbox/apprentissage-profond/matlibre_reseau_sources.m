function sources = matlibre_reseau_sources(reseau, nom)
%MATLIBRE_RESEAU_SOURCES Couches qui alimentent une couche donnée.
%   S = MATLIBRE_RESEAU_SOURCES(RESEAU,NOM) rend, dans l'ordre où elles
%   ont été raccordées, le nom des couches dont la sortie entre dans la
%   couche nommée. L'ordre compte pour une concaténation.
%
%   Exemple :
%      net = dlnetwork({featureInputLayer(2), reluLayer()});
%      matlibre_reseau_sources(net, net.Names{2})
%
%   Voir aussi DLNETWORK, CONNECTLAYERS.
    sources = {};
    connexions = reseau.Connections;
    for k = 1:height(connexions)
        if strcmp(connexions.Destination{k}, nom)
            sources{end + 1} = connexions.Source{k};    %#ok<AGROW>
        end
    end
end
