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
