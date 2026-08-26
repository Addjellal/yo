# Toolbox `coder`

```
% MATLAB Coder — génération de code C.
%
% Le générateur travaille sur l'arbre syntaxique, pas sur le texte : il
% connaît la forme exacte du programme et propage les types et les
% dimensions depuis la signature donnée par « -args ». Le C produit
% n'alloue rien — tableaux de taille fixe, rangés par colonnes comme en
% MATLAB — et les conversions entières saturent, comme dans MATLAB.
%
% Ce qui est traduit
%   scalaires et matrices de taille fixe ;
%   double, single, int8..int64, uint8..uint64, logical, char ;
%   + - .* ./ .^ * ' et les comparaisons, avec diffusion du scalaire ;
%   produit matriciel, transposition, indexation A(i) et A(i,j) ;
%   if / elseif / else, for, while, switch, break, continue, return ;
%   zeros, ones, eye, les fonctions mathématiques usuelles, mod, rem,
%   min, max, sum, prod, mean, abs, size, numel, length, les conversions
%   de classe et isnan / isinf / isfinite.
%
% Ce qui est refusé, explicitement et avec le numéro de ligne
%   cellules, structures, objets, chaînes de caractères variables,
%   nombres complexes, tableaux de taille variable, varargin, varargout,
%   récursivité, fonctions non listées ci-dessus.
%
%   codegen        - Traduit une fonction en C ou C++
%   codegenBuild   - Traduit puis compile avec le compilateur du système
```

## `codegen`

```
CODEGEN Traduit une fonction MATLAB en C.
  CODEGEN('f') traduit f en supposant des entrées scalaires double.
  CODEGEN('f','-args',{...}) donne le type et la taille de chaque entrée :
  chaque case du tableau est un exemple de valeur, dont la classe et les
  dimensions décident du C produit.

  Options, reprises de MATLAB Coder :
     '-args' EXEMPLES   types et tailles des entrées
     '-o' NOM           nom de base des fichiers écrits
     '-d' DOSSIER       dossier de sortie (défaut : le dossier courant)
     '-nargout' N       nombre de sorties à produire
     '-lang:c'          langage C (défaut)
     '-lang:c++'        langage C++, en-tête extern "C"
     '-config' MODE     'lib' (défaut), 'exe' ajoute un main de démonstration
     '-report'          rend la structure du résultat au lieu d'écrire
     '-c'               n'écrit que les sources, sans compiler

  Le C produit n'alloue rien : les tableaux sont de taille fixe, rangés
  par colonnes comme en MATLAB, et les conversions entières saturent.

  Exemple :
     codegen('carreDeTest', '-args', {0}, '-report')
     codegen('produitTest', '-args', {zeros(3,3), zeros(3,1)})

  Voir aussi CODEGENBUILD, CODER.TYPEOF.
```

## `codegenBuild`

```
CODEGENBUILD Génère le C puis le compile avec le compilateur du système.
  [OK,MESSAGE] = CODEGENBUILD('f') écrit f.c et f.h dans un dossier
  temporaire puis les compile en objet.
  CODEGENBUILD('f','-args',{...},'-d',DOSSIER) accepte les mêmes options
  que CODEGEN, plus '-exe' pour produire un exécutable de démonstration.
```

## `coder.typeof`

```
CODER.TYPEOF Décrit le type et la taille d'une entrée pour CODEGEN.
  T = CODER.TYPEOF(EXEMPLE) prend la classe et les dimensions de EXEMPLE.
  T = CODER.TYPEOF(EXEMPLE,TAILLES) impose les dimensions.

  MatLibre ne produit que des tableaux de taille fixe : le troisième
  argument de MATLAB, qui déclare des dimensions variables, est accepté
  puis ignoré, et un avertissement le signale.

  Exemple :
     codegen('f', '-args', {coder.typeof(int32(0), [3 3])})
```

