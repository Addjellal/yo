function lg = connectLayers(lg, source, destination)
%CONNECTLAYERS Raccorde la sortie d'une couche à l'entrée d'une autre.
%   LG = CONNECTLAYERS(LG,SOURCE,DESTINATION) inscrit une arête dans le
%   graphe. Une couche qui attend plusieurs entrées — une addition, une
%   concaténation — reçoit ses arêtes dans l'ordre où on les pose.
%
%   Exemple :
%      lg = layerGraph();
%      lg = addLayers(lg, featureInputLayer(3, 'Name', 'entree'));
%      lg = addLayers(lg, fullyConnectedLayer(2, 'Name', 'dense'));
%      lg = connectLayers(lg, 'entree', 'dense');
%      size(lg.Connections, 1)      % 1
%
%   Voir aussi LAYERGRAPH, ADDLAYERS, DLNETWORK.
    source = matlibre_reseau_nom_seul(source);
    destination = matlibre_reseau_nom_seul(destination);
    if ~any(strcmp(lg.Names, source))
        error('nnet:connectLayers:Source', 'No layer named ''%s''.', source);
    end
    if ~any(strcmp(lg.Names, destination))
        error('nnet:connectLayers:Destination', ...
              'No layer named ''%s''.', destination);
    end
    ajout = table({source}, {destination}, ...
                  'VariableNames', {'Source', 'Destination'});
    lg.Connections = [lg.Connections; ajout];
end
