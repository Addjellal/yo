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
