%% test_graphes.m — graphes orientes et non orientes.
%
% Un graphe se verifie sur ses invariants, non sur ses sorties : la somme
% des degres vaut deux fois le nombre d'aretes, le laplacien a des lignes
% de somme nulle, un arbre couvrant a exactement N-1 aretes, et un tri
% topologique place chaque arc dans le bon sens.
disp('--- graphes ---');

%% ------------------------------------------------ construction
g = graph([1 2 3], [2 3 4]);
assert(numnodes(g) == 4 && numedges(g) == 3);
% Le lemme des poignees de main : la somme des degres compte chaque arete
% deux fois, une par extremite.
assert(sum(degree(g)) == 2 * numedges(g));
assert(isequal(degree(g)', [1 2 2 1]));

% Une matrice d'adjacence donne le meme graphe. Sur un graphe non oriente
% elle est symetrique, et une seule arete par couple en sort.
A = [0 1 0; 1 0 1; 0 1 0];
gA = graph(A);
assert(numnodes(gA) == 3 && numedges(gA) == 2);
assert(isequal(adjacency(gA), A), 'l''aller-retour rend la matrice');
assert(max(max(abs(adjacency(g) - adjacency(g)'))) == 0, ...
       'l''adjacence d''un graphe non oriente est symetrique');

% Le laplacien : degres moins adjacence. Ses lignes somment a zero, donc
% le vecteur constant est dans son noyau — c'est ce qui fait de sa
% deuxieme valeur propre la connectivite algebrique.
L = laplacian(g);
assert(max(abs(sum(L, 2))) < 1e-12);
assert(max(max(abs(L - L'))) < 1e-12);
valeurs = sort(eig(L));
assert(abs(valeurs(1)) < 1e-10, 'zero est toujours valeur propre');
assert(valeurs(2) > 1e-10, 'et il est simple quand le graphe est connexe');

% L'incidence : une colonne par arete, deux uns par colonne.
I = incidence(g);
assert(isequal(size(I), [4 3]));
assert(all(sum(I, 1) == 2));

%% ------------------------------------------------ plus court chemin
% Le detour par 2 coute deux, l'arete directe cinq : Dijkstra prend le
% detour, ce qu'un parcours en largeur ne ferait pas.
p = graph([1 2 1], [2 3 3], [1 1 5]);
[chemin, longueur] = shortestpath(p, 1, 3);
assert(isequal(chemin, [1 2 3]) && abs(longueur - 2) < 1e-12);
% En comptant les aretes et non les poids, l'arete directe gagne.
[cheminBrut, longueurBrute] = shortestpath(p, 1, 3, 'Method', 'unweighted');
assert(isequal(cheminBrut, [1 3]) && longueurBrute == 1);

% Sur un graphe oriente, le chemin suit le sens des arcs.
d = digraph([1 2 3], [2 3 4]);
assert(isequal(shortestpath(d, 1, 4), [1 2 3 4]));
assert(isempty(shortestpath(d, 4, 1)), 'on ne remonte pas un arc');
[~, longueurAbsente] = shortestpath(d, 4, 1);
assert(isinf(longueurAbsente));

% DISTANCES : la matrice est symetrique sur un graphe non oriente, et
% l'inegalite triangulaire y tient.
D = distances(graph([1 2 3], [2 3 4]));
assert(max(max(abs(D - D'))) < 1e-12);
assert(all(diag(D) == 0));
assert(D(1, 4) <= D(1, 2) + D(2, 4) + 1e-12);
assert(D(1, 4) == 3);

%% ------------------------------------------------ connexite
% Deux aretes disjointes font deux composantes.
[groupes, tailles] = conncomp(graph([1 3], [2 4]));
assert(isequal(groupes, [1 1 2 2]));
assert(isequal(tailles, [2 2]));
assert(all(conncomp(graph([1 2 3], [2 3 4])) == 1), 'une chaine est connexe');

% Sur un graphe oriente, forte et faible ne disent pas la meme chose : une
% chaine est faiblement connexe et n'a que des composantes fortes reduites
% a un noeud.
chaine = digraph([1 2], [2 3]);
assert(numel(unique(conncomp(chaine))) == 3, 'aucun retour possible');
assert(numel(unique(conncomp(chaine, 'Type', 'weak'))) == 1);
% Un cycle, lui, est fortement connexe.
cycle = digraph([1 2 3], [2 3 1]);
assert(numel(unique(conncomp(cycle))) == 1);

%% ------------------------------------------------ parcours et arbres
% Largeur et profondeur visitent les memes noeuds, dans des ordres
% differents : c'est la file contre la pile.
etoile = graph([1 1 2], [2 3 4]);
largeur = bfsearch(etoile, 1);
profondeur = dfsearch(etoile, 1);
assert(isequal(sort(largeur), sort(profondeur)));
assert(numel(largeur) == 4);
assert(largeur(1) == 1 && profondeur(1) == 1);
assert(~isequal(largeur, profondeur), 'les deux ordres different ici');

% L'arbre couvrant minimal : N-1 aretes, et il evite l'arete chere.
[arbre, cout] = minspantree(p);
assert(numedges(arbre) == numnodes(p) - 1);
assert(abs(cout - 2) < 1e-12, 'la grande arete est evitee');
assert(numel(unique(conncomp(arbre))) == 1, 'et il reste connexe');

% Le tri topologique place chaque arc dans le sens de l'ordre. Il se lit
% de gauche a droite : MATLAB en rend une ligne, non une colonne.
ordre = toposort(digraph([1 2 1], [2 3 3]));
assert(isrow(ordre));
rang = zeros(1, 3);
rang(ordre) = 1:3;
arcs = [1 2; 2 3; 1 3];
for k = 1:size(arcs, 1)
    assert(rang(arcs(k, 1)) < rang(arcs(k, 2)), 'chaque arc va vers l''avant');
end
% Un cycle n'admet aucun ordre : il faut le dire, non rendre n'importe quoi.
leve = false;
try
    toposort(digraph([1 2 3], [2 3 1]));
catch
    leve = true;
end
assert(leve);

%% ------------------------------------------------ modifications
g2 = addedge(graph([1 2], [2 3]), 3, 4);
assert(numedges(g2) == 3 && numnodes(g2) == 4);
g3 = rmedge(g2, 3, 4);
assert(numedges(g3) == 2);
g4 = rmnode(graph([1 2], [2 3]), 3);
assert(numnodes(g4) == 2 && numedges(g4) == 1, ...
       'retirer un noeud emporte les aretes qui le touchent');
g5 = subgraph(graph([1 2 3], [2 3 4]), [1 2 3]);
assert(numnodes(g5) == 3 && numedges(g5) == 2);
g6 = addnode(graph([1 2], [2 3]), 2);
assert(numnodes(g6) == 5 && numedges(g6) == 2, 'les noeuds ajoutes sont isoles');

% Les noeuds peuvent porter des noms, et tout les accepte.
nomme = graph({'a', 'b'}, {'b', 'c'});
assert(numnodes(nomme) == 3);
assert(isequal(shortestpath(nomme, 'a', 'c'), [1 2 3]));
assert(degree(nomme, 'b') == 2);

%% ------------------------------------------------ oriente : degres
o = digraph([1 1 2], [2 3 3]);
assert(isequal(indegree(o)', [0 1 2]));
assert(isequal(outdegree(o)', [2 1 0]));
assert(sum(indegree(o)) == sum(outdegree(o)), ...
       'chaque arc part d''un noeud et arrive a un autre');
assert(isequal(successors(o, 1)', [2 3]));
assert(isequal(predecessors(o, 3)', [1 2]));

figure();
plot(graph([1 2 3], [2 3 1]));
close all;

%% ------------------------------------------- CYCLES, CHEMINS, CIRCUITS
% Un cycle s'enumere une seule fois : on ne part que de son plus petit
% noeud, et sur un graphe non oriente on ne garde qu'un sens de parcours.
% Sans ces deux precautions, un triangle se compterait six fois.
triangle = graph([1 2 3], [2 3 1]);
assert(hascycles(triangle));
assert(numel(allcycles(triangle)) == 1);
cyclesTriangle = allcycles(triangle);
assert(numel(cyclesTriangle{1}) == 3);
assert(isequal(sort(cyclesTriangle{1}), [1 2 3]));
[~, aretesCycle] = allcycles(triangle);
assert(numel(aretesCycle{1}) == 3);

chaine = graph([1 2], [2 3]);
assert(~hascycles(chaine));
assert(isempty(allcycles(chaine)));

% Le graphe complet a quatre sommets a sept cycles : quatre triangles et
% trois quadrilateres.
complet4 = graph([1 1 1 2 2 3], [2 3 4 3 4 4]);
assert(numel(allcycles(complet4)) == 7);
longueurs = cellfun(@numel, allcycles(complet4));
assert(sum(longueurs == 3) == 4);
assert(sum(longueurs == 4) == 3);

% Une boucle est un cycle ; deux aretes paralleles aussi, et une seule
% fois.
assert(numel(allcycles(graph([1], [1]))) == 1);
assert(numel(allcycles(graph([1 1], [2 2]))) == 1);

% Sur un graphe oriente, les deux sens d'un circuit de longueur deux sont
% bien deux arcs, mais un seul circuit.
assert(numel(allcycles(digraph([1 2], [2 1]))) == 1);
assert(numel(allcycles(digraph([1 2 3], [2 3 1]))) == 1);
assert(isempty(allcycles(digraph([1 2], [2 3]))));

% La base de cycles compte E - N + C elements, et tout cycle en est une
% somme modulo deux. On verifie le compte, qui est ce qui la definit.
assert(numel(cyclebasis(triangle)) == 1);
assert(numel(cyclebasis(complet4)) == numedges(complet4) - numnodes(complet4) + 1);
assert(isempty(cyclebasis(chaine)));

% Tous les chemins simples, et rien qu'eux.
losange = digraph([1 1 2 3], [2 3 4 4]);
assert(numel(allpaths(losange, 1, 4)) == 2);
assert(numel(allpaths(digraph([1 1 2], [2 3 3]), 1, 3)) == 2);
% Un circuit ne fait pas boucler l'enumeration : les chemins restent
% simples.
assert(numel(allpaths(digraph([1 2 2], [2 1 3]), 1, 3)) == 1);
assert(numel(allpaths(triangle, 1, 3)) == 2);
[~, aretesChemin] = allpaths(losange, 1, 4);
assert(all(cellfun(@numel, aretesChemin) == 2));

%% ------------------------------------- SANS CIRCUIT, FERMETURE, REDUCTION
assert(isdag(digraph([1 2], [2 3])));
assert(~isdag(digraph([1 2], [2 1])));
assert(isdag(digraph()));

% La fermeture transitive joint deux noeuds des que l'un mene a l'autre.
ferme = transclosure(digraph([1 2], [2 3]));
assert(numedges(ferme) == 3);
assert(edgecount(ferme, 1, 3) == 1);
% Elle ne garde pas les boucles, meme sur un circuit.
fermeCircuit = transclosure(digraph([1 2 3], [2 3 1]));
assert(numedges(fermeCircuit) == 6);
assert(edgecount(fermeCircuit, 1, 1) == 0);

% La reduction transitive retire ce qu'un chemin plus long rend inutile,
% et garde la meme accessibilite.
reduit = transreduction(digraph([1 1 2], [2 3 3]));
assert(numedges(reduit) == 2);
assert(edgecount(reduit, 1, 3) == 0);
assert(numedges(transclosure(reduit)) == numedges(transclosure(digraph([1 1 2], [2 3 3]))));
% Sur un graphe a circuit elle n'est pas unique : il faut le dire.
refuseCircuit = false;
try
    transreduction(digraph([1 2], [2 1]));
catch err
    refuseCircuit = strcmp(err.identifier, 'MATLAB:digraph:CycleDetected');
end
assert(refuseCircuit);

% La condensation est toujours sans circuit : s'il en restait un, les
% composantes qu'il relie n'en feraient qu'une.
[condense, groupes] = condensation(digraph([1 2 2 3], [2 1 3 4]));
assert(isdag(condense));
assert(numnodes(condense) == 3);
assert(groupes(1) == groupes(2));
assert(isdag(condensation(digraph([1 2 3 4], [2 3 1 1]))));

%% ------------------------------------------------ ARETES ET VOISINAGE
assert(isequal(sort(outedges(triangle, 2)'), [1 2]));
assert(isequal(inedges(digraph([1 2], [3 3]), 3)', [1 2]));
assert(isequal(outedges(digraph([1 2], [2 3]), 2)', 2));
assert(edgecount(graph([1 1], [2 2]), 1, 2) == 2);
assert(edgecount(triangle, 1, 2) == 1);
assert(edgecount(triangle, 1, 1) == 0);
assert(ismultigraph(graph([1 1], [2 2])));
assert(~ismultigraph(triangle));
assert(~ismultigraph(graph([1], [1])));     % une boucle unique n'est pas une repetition
assert(ismultigraph(digraph([1 1], [2 2])));
assert(~ismultigraph(digraph([1 2], [2 1])));   % deux sens, deux arcs distincts

% Les noeuds a portee, classes par distance.
[proches, ecarts] = nearest(graph([1 2], [2 3]), 1, 2);
assert(isequal(proches', [2 3]));
assert(isequal(ecarts', [1 2]));
assert(isequal(nearest(graph([1 2], [2 3]), 1, 1)', 2));
assert(isempty(nearest(graph([1 2], [2 3]), 1, 0)));

%% --------------------------------------------------- RENUMEROTATION
% Renumeroter ne change pas le graphe : le noeud k devient celui qui
% portait le numero ordre(k), et les aretes suivent.
renumerote = reordernodes(graph([1 2], [2 3]), [3 2 1]);
assert(numedges(renumerote) == 2);
assert(isequal(sort(degree(renumerote))', [1 1 2]));
assert(isisomorphic(renumerote, graph([1 2], [2 3])));
avecNoms = reordernodes(graph([1 2], [2 3], [], {'a', 'b', 'c'}), [3 1 2]);
assert(isequal(avecNoms.Noms(:)', {'c', 'a', 'b'}));
refuseOrdre = false;
try
    reordernodes(graph([1 2], [2 3]), [1 1 2]);
catch err
    refuseOrdre = strcmp(err.identifier, 'MATLAB:graph:InvalidNodeOrder');
end
assert(refuseOrdre);

% Retourner les arcs.
retourne = flipedge(digraph([1 2], [2 3]));
assert(isequal(retourne.Arcs, [2 1; 3 2]));
unSeul = flipedge(digraph([1 2], [2 3]), 1, 2);
assert(isequal(unSeul.Arcs, [2 1; 2 3]));

%% ------------------------------------------------------ ISOMORPHISME
% Deux graphes isomorphes ont les memes degres, mais pas sur les memes
% noeuds : c'est l'ensemble des degres qu'il faut comparer.
assert(isisomorphic(graph([1 2], [2 3]), graph([2 3], [3 1])));
assert(~isisomorphic(graph([1 2 3], [2 3 1]), graph([1 2], [2 3])));
% Meme suite de degres, graphes differents : le cycle a six sommets n'est
% pas la reunion de deux triangles.
cycle6 = graph([1 2 3 4 5 6], [2 3 4 5 6 1]);
deuxTriangles = graph([1 2 3 4 5 6], [2 3 1 5 6 4]);
assert(isequal(sort(degree(cycle6)), sort(degree(deuxTriangles))));
assert(~isisomorphic(cycle6, deuxTriangles));
assert(isisomorphic(cycle6, graph([2 3 4 5 6 1], [3 4 5 6 1 2])));
% La permutation rendue transporte bien les aretes.
permutation = isomorphism(graph([1 2], [2 3]), graph([2 3], [3 1]));
assert(numel(permutation) == 3);
transporte = reordernodes(graph([2 3], [3 1]), permutation);
assert(numedges(transporte) == 2);
assert(isempty(isomorphism(graph([1 2 3], [2 3 1]), graph([1 2], [2 3]))));
% Un graphe oriente ne se compare qu'a un graphe oriente.
assert(~isisomorphic(digraph([1 2], [2 3]), graph([1 2], [2 3])));

disp('graphes : toutes les verifications passent');
