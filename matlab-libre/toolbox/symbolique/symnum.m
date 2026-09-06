function e = symnum(valeur)
%SYMNUM Feuille « constante ».
%   E = SYMNUM(VALEUR) construit la feuille {'num', VALEUR} : c'est ainsi
%   qu'un nombre entre dans une expression symbolique.
%
%   Sans elle, un nombre nu ne se distinguerait pas d'un opérateur dans
%   l'arbre. Les constructeurs qui acceptent un nombre l'enveloppent
%   d'eux-mêmes.
%
%   Exemple :
%      symstr(symadd(symnum(2), symnum(3)))    % '2 + 3', non '5'
%      symstr(symsimplify(symadd(symnum(2), symnum(3))))   % '5'
%
%   Voir aussi SYMADD, SYMSIMPLIFY, SYMSTR.
    e = {'num', valeur};
end
