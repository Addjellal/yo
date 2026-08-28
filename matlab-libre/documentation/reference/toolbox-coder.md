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
% Les nombres complexes
%   Un complexe devient une structure de deux double, matlibre_cplx,
%   définie dans l'en-tête produit — c'est la forme du creal_T de MATLAB
%   Coder. Sont traduits : + - .* ./ .^ et leurs formes matricielles,
%   == et ~=, < > <= >= (qui comparent les parties réelles, comme
%   MATLAB), & et |, real, imag, conj, abs, angle, complex, isreal,
%   sqrt, exp, log, sum, prod, mean, le produit matriciel, la
%   transposition simple .' et la transposition conjuguée '.
%   z^n à exposant entier réel passe par carrés successifs, comme
%   MATLAB : (1+2i)^2 rend exactement -3+4i.
%   Comme sous MATLAB Coder, une variable destinée à recevoir un
%   complexe se déclare avec complex(...) avant la boucle qui la
%   remplit ; sans cela l'affectation est refusée, le message donnant le
%   remède.
%
% Ce qui est refusé, explicitement et avec le numéro de ligne
%   cellules, structures, objets, chaînes de caractères variables,
%   complexes single ou entiers, tableaux de taille variable, varargin,
%   varargout, récursivité, fonctions non listées ci-dessus.
%   Le préfixe mlb_ est réservé aux identifiants que le traducteur
%   produit : une variable MATLAB qui le porterait est refusée.
%
%   codegen        - Traduit une fonction en C ou C++
%   codegenBuild   - Traduit puis compile avec le compilateur du système
%   compilateurC   - Trouve un compilateur C sur la machine
%   coder.typeof   - Décrit le type et la taille d'une entrée
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

  Les entrées complexes se déclarent avec COMPLEX : la classe et la
  complexité de l'exemple décident du C produit. Un complexe devient une
  structure matlibre_cplx de deux double, définie dans l'en-tête.

  Exemple :
     codegen('carreDeTest', '-args', {0}, '-report')
     codegen('produitTest', '-args', {zeros(3,3), zeros(3,1)})
     codegen('filtreTest',  '-args', {complex(zeros(1,8))})

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

## `compilateurC`

```
COMPILATEURC Trouve un compilateur C sur la machine.
  NOM = COMPILATEURC() rend le nom de l'exécutable à appeler, ou une
  chaîne vide si aucun compilateur n'est trouvé.

  [NOM,FAMILLE] = COMPILATEURC() rend en plus la famille d'options :
  'gcc' pour cc, gcc et clang, qui partagent la ligne de commande d'Unix.

  Les candidats sont essayés dans l'ordre : cc, gcc, clang. Sous Windows,
  MinGW installe gcc mais pas cc, d'où l'essai des trois — c'est ce qui
  faisait sauter la compilation du C produit dans les tests.

  Visual Studio (cl) n'est pas encore géré : sa ligne de commande n'a
  rien de commun avec celle d'Unix. Il est détecté et signalé plutôt que
  d'être appelé avec des options qu'il ne comprend pas.

  Exemple :
     compilateur = compilateurC();
     if isempty(compilateur)
         disp('pas de compilateur C');
     end

  Voir aussi CODEGEN, CODEGENBUILD.
```

