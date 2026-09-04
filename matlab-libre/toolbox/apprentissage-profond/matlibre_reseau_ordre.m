function ordre = matlibre_reseau_ordre(noms, connexions)
%MATLIBRE_RESEAU_ORDRE Ordre de calcul des couches d'un graphe.
%   O = MATLIBRE_RESEAU_ORDRE(NOMS,CONNEXIONS) rend les indices des
%   couches dans un ordre où chacune vient après tout ce qui l'alimente.
%   C'est le tri topologique : il existe si et seulement si le graphe n'a
%   pas de cycle, ce qui est la condition pour qu'un passage avant ait un
%   sens.
%
%   Exemple :
%      lg = layerGraph({reluLayer(), reluLayer()});
%      matlibre_reseau_ordre(lg.Names, lg.Connections)     % 1 2
%
%   Voir aussi DLNETWORK, LAYERGRAPH.
    n = numel(noms);
    entrant = zeros(1, n);
    sources = cell(1, n);
    if height(connexions) > 0
        for k = 1:height(connexions)
            depart = find(strcmp(noms, connexions.Source{k}), 1);
            arrivee = find(strcmp(noms, connexions.Destination{k}), 1);
            entrant(arrivee) = entrant(arrivee) + 1;
            sources{depart}(end + 1) = arrivee;
        end
    end
    file = find(entrant == 0);
    ordre = zeros(1, 0);
    while ~isempty(file)
        courant = file(1);
        file(1) = [];
        ordre(end + 1) = courant;      %#ok<AGROW>
        for suivant = sources{courant}
            entrant(suivant) = entrant(suivant) - 1;
            if entrant(suivant) == 0
                file(end + 1) = suivant;   %#ok<AGROW>
            end
        end
    end
    if numel(ordre) ~= n
        error('nnet:dlnetwork:Cycle', ...
              'Le graphe de couches contient un cycle.');
    end
end
