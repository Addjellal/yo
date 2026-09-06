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
       └── bibliotheque/       651 fonctions natives, par domaine
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

## Algèbre linéaire

Tout est écrit dans `AlgebreLineaire.cpp` : LU avec pivot partiel, QR de
Householder, Cholesky, SVD par Jacobi unilatérale, valeurs propres par
Jacobi (matrices symétriques) ou Hessenberg + QR à décalage de Wilkinson
(cas général), exponentielle de matrice par mise à l'échelle et
approximant de Padé.

Si LAPACK et BLAS sont trouvés à la compilation, ils sont liés et
serviront aux grandes matrices ; sans eux, rien ne manque.

## Fourier

`Signal.cpp` contient une FFT complète : Cooley-Tukey itératif quand la
longueur est une puissance de deux, algorithme de Bluestein sinon. Une
transformée de longueur 3 ou 1009 est donc exacte, pas approchée par
remplissage de zéros.

## Graphique

Le rendu se fait en SVG, écrit à la main dans `src/graphique`. C'est un
format vectoriel, lisible, que tous les navigateurs affichent, et qui ne
demande aucune bibliothèque. `print` et `saveas` écrivent le fichier ;
`matlibre_svg` rend le texte, ce qui permet de tester le tracé.

## Ce que coûte un interpréteur à parcours d'arbre

Une instruction scalaire coûte de l'ordre de 8 µs, un appel de fonction
une dizaine. Les opérations vectorisées, elles, tournent à la vitesse du
C++ : `sum(x)` sur un million d'éléments est une boucle native. La règle
est donc celle de MATLAB — vectoriser plutôt que boucler — et elle est ici
plus impérieuse encore.
