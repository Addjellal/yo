function lg = connectLayers(lg, source, destination)
%CONNECTLAYERS Raccorde la sortie d'une couche à l'entrée d'une autre.
%   LG = CONNECTLAYERS(LG,SOURCE,DESTINATION) inscrit une arête dans le
%   graphe. Une couche qui attend plusieurs entrées — une addition, une
%   concaténation — reçoit ses arêtes dans l'ordre où on les pose.
%
%   Exemple :
%      lg = connectLayers(lg, 'conv1', 'somme');
%
%   Voir aussi LAYERGRAPH, ADDLAYERS, DLNETWORK.
    source = matlibre_reseau_nom_seul(source);
    destination = matlibre_reseau_nom_seul(destination);
    if ~any(strcmp(lg.Names, source))
        error('nnet:connectLayers:Source', 'Aucune couche nommée « %s ».', source);
    end
    if ~any(strcmp(lg.Names, destination))
        error('nnet:connectLayers:Destination', ...
              'Aucune couche nommée « %s ».', destination);
    end
    ajout = table({source}, {destination}, ...
                  'VariableNames', {'Source', 'Destination'});
    lg.Connections = [lg.Connections; ajout];
end
