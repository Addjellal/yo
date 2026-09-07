function [arbre, cout] = matlibre_graphe_prim(g)
%MATLIBRE_GRAPHE_PRIM Arbre couvrant de poids minimal.
%   L'algorithme de Prim fait croître un arbre depuis un nœud, en lui
%   ajoutant chaque fois l'arête la moins chère qui mène hors de lui.
%   Le choix glouton est ici optimal : c'est la propriété de coupe — la
%   plus légère arête traversant une coupe appartient à un arbre minimal.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [t, c] = matlibre_graphe_prim(graph([1 2 1], [2 3 3], [1 1 5]));
%      c                               % 2 : la grande arete est evitee
%
%   Voir aussi MINSPANTREE, GRAPH.
    n = g.Nombre;
    dansArbre = false(n, 1);
    if n == 0
        arbre = graph();
        cout = 0;
        return
    end
    dansArbre(1) = true;
    arcs = zeros(0, 2);
    poids = zeros(0, 1);
    cout = 0;
    for pas = 1:n - 1   %#ok<NASGU>
        meilleur = inf;
        choisi = 0;
        for k = 1:size(g.Arcs, 1)
            a = g.Arcs(k, 1);
            b = g.Arcs(k, 2);
            if dansArbre(a) == dansArbre(b), continue, end
            if g.Poids(k) < meilleur
                meilleur = g.Poids(k);
                choisi = k;
            end
        end
        if choisi == 0
            break   % le graphe n'est pas connexe : la foret s'arrete la
        end
        arcs(end + 1, :) = g.Arcs(choisi, :);   %#ok<AGROW>
        poids(end + 1, 1) = g.Poids(choisi);    %#ok<AGROW>
        dansArbre(g.Arcs(choisi, 1)) = true;
        dansArbre(g.Arcs(choisi, 2)) = true;
        cout = cout + meilleur;
    end
    arbre = graph(arcs(:, 1), arcs(:, 2), poids);
    arbre.Nombre = n;
    arbre.Noms = g.Noms;
end
