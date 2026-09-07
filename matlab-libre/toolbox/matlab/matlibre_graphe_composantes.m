function [groupes, tailles] = matlibre_graphe_composantes(g, options)
%MATLIBRE_GRAPHE_COMPOSANTES Composantes connexes d'un graphe.
%   Sur un GRAPH, la connexité est unique. Sur un DIGRAPH il y en a deux :
%   forte — chaque nœud atteint chaque autre en suivant le sens des arcs —
%   et faible, où l'on ignore l'orientation. La forte est celle par
%   défaut, comme dans MATLAB.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   La composante forte se trouve par la double accessibilité : deux nœuds
%   sont dans la même si chacun atteint l'autre. C'est plus lent que
%   Tarjan, mais c'est la définition même, et l'on voit ce qu'on calcule.
%
%   Exemple :
%      matlibre_graphe_composantes(graph([1 3], [2 4]), {})   % 1 1 2 2
%
%   Voir aussi CONNCOMP, GRAPH, DIGRAPH.
    if nargin < 2, options = {}; end
    faible = ~isa(g, 'digraph');
    for k = 1:2:numel(options) - 1
        if strcmpi(char(options{k}), 'type')
            faible = strcmpi(char(options{k + 1}), 'weak');
        end
    end
    n = g.Nombre;
    accessible = false(n);
    for s = 1:n
        atteints = parcourir(g, s, faible);
        accessible(s, atteints) = true;
        accessible(s, s) = true;
    end
    if ~faible
        ensemble = accessible & accessible';
    else
        ensemble = accessible | accessible';
    end
    groupes = zeros(1, n);
    numero = 0;
    for s = 1:n
        if groupes(s) ~= 0, continue, end
        numero = numero + 1;
        groupes(ensemble(s, :) & groupes == 0) = numero;
        groupes(s) = numero;
    end
    tailles = accumarray(groupes(:), 1)';
end

function atteints = parcourir(g, depart, ignorerSens)
    n = g.Nombre;
    vu = false(n, 1);
    pile = depart;
    vu(depart) = true;
    while ~isempty(pile)
        courant = pile(end);
        pile(end) = [];
        suivants = matlibre_graphe_voisins(g, courant, false);
        if ignorerSens
            suivants = [suivants; matlibre_graphe_voisins(g, courant, true)];
        end
        for v = suivants(:)'
            if ~vu(v)
                vu(v) = true;
                pile(end + 1) = v;   %#ok<AGROW>
            end
        end
    end
    atteints = find(vu)';
end
