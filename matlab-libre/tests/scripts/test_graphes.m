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

% Le tri topologique place chaque arc dans le sens de l'ordre.
ordre = toposort(digraph([1 2 1], [2 3 3]));
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

disp('graphes : toutes les verifications passent');
