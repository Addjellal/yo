function e = symadd(a, b)
%SYMADD Somme de deux expressions.
%   E = SYMADD(A,B) construit l'arbre {'+', A, B} sans rien
%   évaluer.
%
%   Les expressions se représentent par des arbres, sous forme de
%   cellules : le premier élément est l'opérateur, les suivants ses
%   opérandes. C'est la représentation la plus simple qui permette de
%   dériver, de substituer et de simplifier sans jamais évaluer.
%
%   Ces constructeurs ne calculent rien : ils assemblent. C'est
%   SYMSIMPLIFY qui réduit, SYMSUBS qui substitue et SYMSTR qui écrit.
%
%   Exemple :
%      x = sym('x');
%      symstr(symsimplify(symadd(symnum(0), x)))
%
%   Voir aussi SYMSIMPLIFY, SYMSTR, SYMSUBS, SYMNUM.
    e = {'+', a, b};
end
