function lg = layerGraph(couches)
%LAYERGRAPH Graphe de couches, éventuellement ramifié.
%   LG = LAYERGRAPH(COUCHES) construit un graphe où les couches se suivent
%   dans l'ordre donné. COUCHES est un tableau de cellules de couches.
%
%   LG = LAYERGRAPH() construit un graphe vide, qu'on remplit par
%   ADDLAYERS puis qu'on raccorde par CONNECTLAYERS. C'est ainsi qu'on
%   décrit un réseau qui n'est pas une simple chaîne : une connexion
%   résiduelle, deux branches parallèles réunies plus loin.
%
%   Le graphe est une structure de trois champs : Layers, les couches ;
%   Names, leurs noms — attribués d'après leur type quand ils manquent —
%   et Connections, une table de deux colonnes qui dit ce qui alimente
%   quoi.
%
%   Exemple :
%      lg = layerGraph({featureInputLayer(4), fullyConnectedLayer(3), ...
%                       softmaxLayer()});
%      height(lg.Connections)      % 2
%
%   Voir aussi ADDLAYERS, CONNECTLAYERS, DLNETWORK, TRAINNETWORK.
    if nargin < 1
        couches = {};
    end
    if ~iscell(couches)
        couches = {couches};
    end
    lg = struct('Layers', {{}}, 'Names', {{}}, ...
                'Connections', table(cell(0, 1), cell(0, 1), ...
                                     'VariableNames', {'Source', 'Destination'}));
    if isempty(couches)
        return
    end
    lg = addLayers(lg, couches);
    for k = 2:numel(lg.Names)
        lg = connectLayers(lg, lg.Names{k - 1}, lg.Names{k});
    end
end
