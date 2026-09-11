function [ok, permutation] = matlibre_graphe_isomorphe(g, h)
%MATLIBRE_GRAPHE_ISOMORPHE Deux graphes se correspondent-ils ?
%   [OK,P] = MATLIBRE_GRAPHE_ISOMORPHE(G,H) cherche une permutation des
%   nœuds de G qui donne H : P(i) est le nœud de H auquel correspond le
%   nœud i de G. OK est faux s'il n'en existe aucune.
%
%   La recherche est un retour sur trace, guidé par les degrés : deux
%   nœuds ne peuvent se correspondre que s'ils ont le même degré, ce qui
%   élague l'arbre avant de l'explorer. Aucun algorithme polynomial n'est
%   connu pour ce problème ; sur de grands graphes réguliers, la
%   recherche peut donc être longue.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_graphe_isomorphe(graph([1 2], [2 3]), graph([2 3], [3 1]))
%
%   Voir aussi ISISOMORPHIC, ISOMORPHISM.
    ok = false;
    permutation = [];
    if isa(g, 'digraph') ~= isa(h, 'digraph')
        return
    end
    n = g.Nombre;
    if h.Nombre ~= n || numedges(g) ~= numedges(h)
        return
    end
    A = pleine(g, n);
    B = pleine(h, n);
    degresG = signature(A);
    degresH = signature(B);
    % Ce sont les colonnes qu'il faut comparer, en tant qu'ensemble : deux
    % graphes isomorphes ont les mêmes degrés, mais pas forcément sur les
    % mêmes nœuds. Trier chaque colonne sur place ne dirait rien.
    if ~isequal(sortrows(degresG'), sortrows(degresH'))
        return
    end

    correspondance = zeros(1, n);
    pris = false(1, n);
    % On place d'abord les nœuds les plus contraints : moins ils ont de
    % candidats, plus tôt l'impasse se voit.
    candidatsParNoeud = cell(1, n);
    for i = 1:n
        candidatsParNoeud{i} = find(all(degresH == degresG(:, i), 1));
    end
    [~, ordre] = sort(cellfun(@numel, candidatsParNoeud));
    ok = placer(1);
    if ok
        permutation = correspondance;
    else
        permutation = [];
    end

    function reussi = placer(rang)
        if rang > n
            reussi = true;
            return
        end
        i = ordre(rang);
        reussi = false;
        for j = candidatsParNoeud{i}
            if pris(j)
                continue
            end
            if ~compatible(i, j, rang)
                continue
            end
            correspondance(i) = j;
            pris(j) = true;
            if placer(rang + 1)
                reussi = true;
                return
            end
            pris(j) = false;
            correspondance(i) = 0;
        end
    end

    function bon = compatible(i, j, rang)
        bon = true;
        for r = 1:rang-1
            p = ordre(r);
            q = correspondance(p);
            if A(i, p) ~= B(j, q) || A(p, i) ~= B(q, j)
                bon = false;
                return
            end
        end
    end
end

function A = pleine(g, n)
% Une matrice d'adjacence qui compte les arêtes multiples et les boucles.
    A = zeros(n, n);
    for k = 1:size(g.Arcs, 1)
        a = g.Arcs(k, 1);
        b = g.Arcs(k, 2);
        A(a, b) = A(a, b) + 1;
        if ~isa(g, 'digraph') && a ~= b
            A(b, a) = A(b, a) + 1;
        end
    end
end

function s = signature(A)
% Degré sortant et degré entrant : sur un graphe non orienté les deux
% coïncident, et la signature se réduit au degré.
    s = [sum(A, 2)'; sum(A, 1)];
end
