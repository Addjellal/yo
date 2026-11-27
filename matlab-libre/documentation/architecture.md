# Architecture

MatLibre est un interpréteur du langage MATLAB écrit en C++17, sans
dépendance obligatoire. Le code se lit de bas en haut : le texte devient
des jetons, les jetons un arbre, l'arbre est parcouru.

```
   source .m
       │
       ▼
   Lexeur.cpp          jetons      ← lève les deux ambiguïtés du langage
       │
       ▼
   Analyseur.cpp       arbre       ← priorités documentées par MathWorks
       │
       ▼
   Interpreteur.cpp    exécution   ← portées, appels, contrôle de flux
       │
       ├── Indexation.cpp      lecture et écriture indexées
       ├── Operations.cpp      opérateurs et expansion implicite
       ├── AlgebreLineaire.cpp LU, QR, Cholesky, SVD, valeurs propres
       ├── Affichage.cpp       mise en forme des résultats
       ├── FichierMat.cpp      le format MAT, lecture et écriture
       ├── Compression.cpp     DEFLATE, pour les MAT compressés
       ├── Suggestion.cpp      « Did you mean: » sur une faute de frappe
       └── bibliotheque/       690 fonctions natives, par domaine
```

## Le type unique

Tout est un tableau, comme dans MATLAB. Une seule classe C++, `Valeur`,
porte les dimensions, la classe MATLAB (`double`, `int32`, `cell`,
`struct`, `string`, `function_handle`…) et les données.

Les nombres sont toujours stockés en `double`, y compris pour `int8` ou
`single` : la saturation et l'arrondi se font au moment des opérations.
C'est plus simple qu'un gabarit par type, et le comportement observable
est le même — `int8(200)` vaut bien 127, `int32(7)/int32(2)` vaut bien 4.

Le rangement est celui de MATLAB : par colonnes.

## Les deux ambiguïtés du langage

Elles se règlent dans le lexeur, pas dans l'analyseur :

1. **L'apostrophe** est soit la transposition (`A'`), soit le début d'une
   chaîne (`'abc'`). Elle transpose quand le jeton précédent termine une
   valeur — identificateur, nombre, `)`, `]`, `}`, `'`, ou `end` — sauf à
   l'intérieur de crochets où un blanc la précède : `[a 'x']` contient
   bien une chaîne.

2. **L'espace compte** dans `[ ]` et `{ }` : `[1 -2]` fait deux éléments,
   `[1 - 2]` un seul. Chaque jeton mémorise s'il est précédé et suivi d'un
   blanc ; l'analyseur tranche au moment de lire un élément.

## Priorité des opérateurs

Celle de la documentation MathWorks, de la plus forte à la plus faible :

```
'  .'  ^  .^        transposition et puissance (associatives à gauche)
+  -  ~             unaires
*  /  \  .*  ./  .\ produits et quotients
+  -                somme et différence
:                   deux-points
<  <=  >  >=  ==  ~= comparaisons
&                   et élément par élément
|                   ou élément par élément
&&                  et à court-circuit
||                  ou à court-circuit
```

Ainsi `2^3^2` vaut 64 et `-2^2` vaut -4, comme dans MATLAB.

## Indexation

`Indexation.cpp` est la partie la plus subtile. Elle traite, pour toutes
les classes :

- l'indexation linéaire et par dimension, le deux-points magique, `end` ;
- l'indexation logique ;
- la forme du résultat (l'orientation de la source l'emporte quand une
  source vecteur est indexée par un vecteur) ;
- la croissance automatique à l'écriture, avec remplissage ;
- la suppression par `A(i) = []`, réservée aux indices entre parenthèses :
  `s.champ = []` pose une valeur vide, il ne retire pas le champ ;
- les chaînes d'accès imbriquées `a.b(3).c{2} = x`, traitées par récursion.

Les tableaux ne sont copiés qu'une fois par affectation indexée : la copie
de travail est ensuite déplacée de proche en proche.

Les doubles d'une valeur (`re`, `im`) vivent dans un `TamponDouble`
(`Tampon.h`), partagé entre copies jusqu'à la première écriture, comme
dans MATLAB : `b = a`, passer `a` à une fonction ou le ranger dans une
cellule ne recopie rien, et seul celui des deux qu'on modifie se
détache. Les accès en lecture partagent ; tout accès qui peut écrire
(l'opérateur `[]` non const, `data()`, `begin()`, `resize`...) détache
d'abord un tampon partagé. Deux cents appels d'une fonction sur un
tableau de seize mégaoctets passent ainsi de trois secondes à une
milliseconde.

Une fonction native qui ne fait que lire son argument le prend donc par
référence const (`const Valeur& v = args[0]`) : lu par une copie non
const, `v.re[k]` détache le tampon au premier accès — une recopie
entière — puis teste à chaque accès qu'il est bien à soi. `sort`
gagnait ainsi un quart de son temps.

## Fonctions et portées

Une portée est une table de noms. La pile de portées sert aussi à
`evalin` et `assignin`. Les variables globales et persistantes vivent dans
l'interpréteur, la portée n'en garde qu'un lien.

Une poignée de fonction anonyme capture l'espace de travail au moment de
sa création — comme MATLAB — et retient aussi la fonction où elle est née,
pour que les sous-fonctions du même fichier lui restent visibles.

Les fichiers `.m` sont indexés une fois par dossier du chemin de
recherche ; la résolution d'un nom est alors une consultation de table.
L'ordre est celui de MATLAB : variable, sous-fonction du fichier, méthode
de classe, fichier du chemin, fonction native.

Un nom qu'aucune de ces tables ne connaît lève
`MATLAB:UndefinedFunction` en gardant le nom à part (`nomInconnu`). Si
l'erreur est née dans la commande tapée elle-même, la console et le
bureau cherchent le nom connu le plus proche (distance d'édition à
transpositions, une lettre mise pour un chiffre comptant double) et
proposent la commande corrigée, comme MATLAB. Le message que voient
`try/catch` et `MException` n'en porte rien.

## Algèbre linéaire

Tout est écrit dans `AlgebreLineaire.cpp` : LU avec pivot partiel, QR de
Householder, Cholesky, SVD par Jacobi unilatérale, valeurs propres par
Jacobi (matrices symétriques) ou Hessenberg + QR à décalage de Wilkinson
(cas général), exponentielle de matrice par mise à l'échelle et
approximant de Padé.

Rien n'est délégué à LAPACK ni à BLAS : c'est ce qui rend `eig` et `svd`
lents sur les grandes matrices denses (0,27 s et 0,44 s pour 300×300, où
MATLAB met quelques millisecondes). Les brancher, en dépendance
facultative, est une proposition de `audit-reprise.md`.

## Fourier

`Signal.cpp` contient une FFT complète : Cooley-Tukey itératif quand la
longueur est une puissance de deux, algorithme de Bluestein sinon. Une
transformée de longueur 3 ou 1009 est donc exacte, pas approchée par
remplissage de zéros.

## Graphique

Une figure se dessine une seule fois, par `dessinerFigure`
(`src/graphique/Dessin.cpp`), sur une `Toile` (`Toile.h`) : quelques
primitives — traits, polygones, rectangles, cercles, textes en morceaux,
découpe. La mise en page, les graduations, la légende et la barre de
couleurs ne connaissent que la toile.

Deux toiles l'implantent. `ToileSVG` écrit du SVG — un format vectoriel,
lisible, que tous les navigateurs affichent, et qui ne demande aucune
bibliothèque : `print` et `saveas` écrivent le fichier, `matlibre_svg`
rend le texte, ce qui permet de tester le tracé. La toile du bureau
(`VueFigure.cpp`) peint avec QPainter. La fenêtre montre donc exactement
ce que `print` écrirait ; une nouveauté du dessin s'écrit une fois.

## Ce que coûte un interpréteur à parcours d'arbre

Une instruction scalaire coûte de l'ordre d'une demi-microseconde
(`s = s + k*0.5`, mesuré par l'audit de reprise), dont un quart en
allocations : chaque scalaire est une `Valeur` qui alloue ses dimensions
et son tampon. Les opérations vectorisées, elles, tournent à la vitesse du
C++ : `sum(x)` sur un million d'éléments est une boucle native. La règle
est donc celle de MATLAB — vectoriser plutôt que boucler — et elle est ici
plus impérieuse encore.
