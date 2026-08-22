# Toolbox `matlab`

```
% MATLAB de base — fonctions écrites dans le langage lui-même.
%
% Les fonctions élémentaires (zeros, size, sum, fft, plot…) sont natives,
% écrites en C++ dans src/. Ce dossier complète le noyau par ce qui
% s'exprime plus clairement en langage MATLAB.
%
%   nextpow2      - Exposant de la puissance de deux immédiatement supérieure
%   pow2          - 2 élevé à une puissance
%   rat           - Approximation rationnelle
%   perms         - Toutes les permutations
%   vecnorm       - Norme de chaque colonne
%   rescale       - Remise à l'échelle sur [0,1]
%   bounds        - Minimum et maximum en un appel
%   uniquetol     - Valeurs distinctes à une tolérance près
%   ismembertol   - Appartenance à une tolérance près
%   validatestring- Complétion d'une option textuelle
%   iskeyword     - Mot réservé du langage ?
%   matlabroot    - Racine de l'installation
%   peaks         - Surface d'essai à trois bosses
%   humps         - Fonction d'essai à deux pics
%   fliplr2       - (interne) inversion utilisée par les démonstrations
```

## `bounds`

```
BOUNDS Minimum et maximum en un seul appel.
  [B,H] = BOUNDS(X) rend le plus petit et le plus grand élément.
```

## `humps`

```
HUMPS Fonction d'essai à deux pics, utilisée par les démonstrations.
  Y = HUMPS(X) évalue 1/((x-0.3)^2+0.01) + 1/((x-0.9)^2+0.04) - 6.
```

## `iskeyword`

```
ISKEYWORD Mot réservé du langage ?
  ISKEYWORD rend la liste des mots réservés.
  ISKEYWORD(NOM) dit si NOM en fait partie.
```

## `ismembertol`

```
ISMEMBERTOL Appartenance à un ensemble, à une tolérance près.
```

## `matlabroot`

```
MATLABROOT Racine de l'installation de MatLibre.
```

## `nextpow2`

```
NEXTPOW2 Exposant de la puissance de deux immédiatement supérieure.
  P = NEXTPOW2(N) rend le plus petit entier P tel que 2^P >= abs(N).
  Pour un tableau, le calcul se fait élément par élément.

  Exemple :
     nextpow2(1000)   % 10
```

## `peaks`

```
PEAKS Surface d'essai à trois bosses et trois creux.
  Z = PEAKS(N) évalue la fonction sur une grille N x N de [-3,3]^2.
  [X,Y,Z] = PEAKS(N) rend aussi la grille.

  La formule est celle de la documentation :
     z = 3(1-x)^2 e^{-x^2-(y+1)^2} - 10(x/5 - x^3 - y^5) e^{-x^2-y^2}
         - 1/3 e^{-(x+1)^2 - y^2}
```

## `perms`

```
PERMS Toutes les permutations des éléments d'un vecteur.
  P = PERMS(V) rend une matrice dont chaque ligne est une permutation
  de V. L'ordre suit celui de MATLAB : lexicographique inverse.
```

## `pow2`

```
POW2 Puissance de deux, ou mantisse mise à l'échelle.
  Y = POW2(X) rend 2.^X.
  Y = POW2(F,E) rend F .* 2.^E.
```

## `rat`

```
RAT Approximation rationnelle par fractions continues.
  [N,D] = RAT(X) rend deux entiers tels que N/D vaut X à la tolérance
  par défaut près (1e-6 fois la valeur).
  S = RAT(X) rend la chaîne « n/d ».
```

## `rescale`

```
RESCALE Remise à l'échelle linéaire d'un tableau.
  Y = RESCALE(X) ramène les valeurs dans [0,1].
  Y = RESCALE(X,A,B) les ramène dans [A,B].
```

## `uniquetol`

```
UNIQUETOL Valeurs distinctes à une tolérance près.
  U = UNIQUETOL(X,TOL) regroupe les valeurs dont l'écart relatif est
  inférieur à TOL (1e-6 par défaut).
```

## `validatestring`

```
VALIDATESTRING Complète une option textuelle parmi une liste.
  S = VALIDATESTRING(CHAINE,OPTIONS) rend l'élément de OPTIONS dont
  CHAINE est un préfixe, sans distinction de casse. Une erreur est levée
  si aucun ou plusieurs éléments correspondent.
```

## `vecnorm`

```
VECNORM Norme de chaque vecteur d'un tableau.
  N = VECNORM(A) rend la norme 2 de chaque colonne.
  N = VECNORM(A,P) utilise la norme P.
  N = VECNORM(A,P,DIM) travaille le long de la dimension DIM.
```

