function [cycles, aretes] = matlibre_graphe_base_cycles(g)
%MATLIBRE_GRAPHE_BASE_CYCLES Base de cycles fondamentaux.
%   [CYCLES,ARETES] = MATLIBRE_GRAPHE_BASE_CYCLES(G) rend une base de
%   l'espace des cycles : une forêt couvrante est construite, et chaque
%   arête restée hors de la forêt ferme exactement un cycle.
%
%   La base compte E - N + C éléments, où C est le nombre de composantes.
%   Tout cycle du graphe est une somme, arête par arête et modulo deux,
%   de ces cycles-là : c'est ce qui en fait une base, et la raison pour
%   laquelle on n'a pas besoin de les énumérer tous.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      numel(matlibre_graphe_base_cycles(graph([1 2 3], [2 3 1])))   % 1
%
%   Voir aussi CYCLEBASIS, ALLCYCLES, MINSPANTREE.
    n = g.Nombre;
    m = size(g.Arcs, 1);
    parent = zeros(1, n);
    areteParent = zeros(1, n);
    profondeur = zeros(1, n);
    vus = false(1, n);
    dansForet = false(1, m);

    for racine = 1:n
        if vus(racine)
            continue
        end
        vus(racine) = true;
        parent(racine) = 0;
        profondeur(racine) = 0;
        file = racine;
        while ~isempty(file)
            courant = file(1);
            file(1) = [];
            for arete = matlibre_graphe_aretes_sortantes(g, courant)
                suivant = matlibre_graphe_autre_bout(g, arete, courant);
                if ~vus(suivant)
                    vus(suivant) = true;
                    parent(suivant) = courant;
                    areteParent(suivant) = arete;
                    profondeur(suivant) = profondeur(courant) + 1;
                    dansForet(arete) = true;
                    file(end + 1) = suivant;   %#ok<AGROW>
                end
            end
        end
    end

    cycles = {};
    aretes = {};
    for arete = 1:m
        if dansForet(arete)
            continue
        end
        a = g.Arcs(arete, 1);
        b = g.Arcs(arete, 2);
        if a == b
            cycles{end + 1} = a;              %#ok<AGROW>
            aretes{end + 1} = arete;          %#ok<AGROW>
            continue
        end
        [chemin, suite] = remonter(a, b, parent, areteParent, profondeur);
        cycles{end + 1} = chemin;             %#ok<AGROW>
        aretes{end + 1} = [suite arete];      %#ok<AGROW>
    end
end

function [chemin, suite] = remonter(a, b, parent, areteParent, profondeur)
% Le cycle fondamental d'une arête hors forêt est le chemin qui joint ses
% deux extrémités dans la forêt, refermé par elle. On remonte jusqu'à
% l'ancêtre commun, en égalisant d'abord les profondeurs.
    gauche = a;
    droite = b;
    montee = [];
    descente = [];
    areteMontee = [];
    areteDescente = [];
    while profondeur(gauche) > profondeur(droite)
        montee(end + 1) = gauche;                    %#ok<AGROW>
        areteMontee(end + 1) = areteParent(gauche);  %#ok<AGROW>
        gauche = parent(gauche);
    end
    while profondeur(droite) > profondeur(gauche)
        descente(end + 1) = droite;                    %#ok<AGROW>
        areteDescente(end + 1) = areteParent(droite);  %#ok<AGROW>
        droite = parent(droite);
    end
    while gauche ~= droite
        montee(end + 1) = gauche;                      %#ok<AGROW>
        areteMontee(end + 1) = areteParent(gauche);    %#ok<AGROW>
        gauche = parent(gauche);
        descente(end + 1) = droite;                    %#ok<AGROW>
        areteDescente(end + 1) = areteParent(droite);  %#ok<AGROW>
        droite = parent(droite);
    end
    chemin = [montee gauche fliplr(descente)];
    suite = [areteMontee fliplr(areteDescente)];
end
