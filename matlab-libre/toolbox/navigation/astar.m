function [chemin, cout] = astar(grille, depart, arrivee)
%ASTAR Plus court chemin sur une grille d'occupation (0 libre, 1 occupé).
%   [CHEMIN,COUT] = ASTAR(GRILLE,[i j],[i j]) rend la suite des cases
%   parcourues, une par ligne, et le coût total. Sans chemin, il rend une
%   liste vide et un coût infini — ce qui est un résultat, non une erreur.
%
%   A* est Dijkstra guidé par une estimation de ce qui reste à parcourir.
%   L'heuristique employée ici est la distance de Manhattan, qui ne
%   surestime jamais le coût restant sur une grille à quatre voisins :
%   c'est ce qui garantit que le chemin trouvé est le plus court, et non
%   seulement un chemin court.
%
%   Sans obstacle, le coût est exactement la distance de Manhattan entre
%   les deux cases : c'est la vérification à faire.
%
%   Exemple :
%      grille = zeros(12); grille(4:9, 6) = 1;
%      [chemin, cout] = astar(grille, [1 1], [12 12]);
%      size(chemin, 1)                 % le nombre de cases
%
%   Voir aussi PUREPURSUIT, BINARYOCCUPANCYMAP.
    [h, l] = size(grille);
    ouverts = depart;
    g = inf(h, l);
    g(depart(1), depart(2)) = 0;
    parent = zeros(h, l, 2);
    ferme = false(h, l);
    while ~isempty(ouverts)
        meilleur = 1;
        meilleurScore = inf;
        for k = 1:size(ouverts, 1)
            n = ouverts(k, :);
            score = g(n(1), n(2)) + heuristique(n, arrivee);
            if score < meilleurScore
                meilleurScore = score;
                meilleur = k;
            end
        end
        courant = ouverts(meilleur, :);
        ouverts(meilleur, :) = [];
        if courant(1) == arrivee(1) && courant(2) == arrivee(2)
            chemin = arrivee;
            cout = g(arrivee(1), arrivee(2));
            n = arrivee;
            while ~(n(1) == depart(1) && n(2) == depart(2))
                n = [parent(n(1), n(2), 1), parent(n(1), n(2), 2)];
                chemin = [n; chemin];
            end
            return;
        end
        ferme(courant(1), courant(2)) = true;
        for di = -1:1
            for dj = -1:1
                if abs(di) + abs(dj) ~= 1
                    continue;
                end
                a = courant(1) + di;
                b = courant(2) + dj;
                if a < 1 || a > h || b < 1 || b > l || grille(a, b) ~= 0 || ferme(a, b)
                    continue;
                end
                candidat = g(courant(1), courant(2)) + 1;
                if candidat < g(a, b)
                    g(a, b) = candidat;
                    parent(a, b, 1) = courant(1);
                    parent(a, b, 2) = courant(2);
                    ouverts(end+1, :) = [a b];
                end
            end
        end
    end
    chemin = [];
    cout = inf;
end

function d = heuristique(a, b)
    d = abs(a(1) - b(1)) + abs(a(2) - b(2));
end
