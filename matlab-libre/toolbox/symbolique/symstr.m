function s = symstr(e)
%SYMSTR Écriture lisible d'une expression symbolique.
%   S = SYMSTR(E) rend l'expression sous forme de texte, avec les
%   parenthèses qu'impose la priorité des opérateurs — ni plus ni moins.
%
%   C'est la seule fonction qui regarde l'arbre pour le rendre à un
%   lecteur : toutes les autres le transforment. Un arbre non simplifié
%   s'écrit tel quel, ce qui permet de voir ce que SYMSIMPLIFY a fait.
%
%   Les parenthèses sont celles qu'impose la priorité des opérateurs, et
%   pas une de plus : « x^2 + 2*x + 1 » s'écrit ainsi, non
%   « (((x^2) + (2*x)) + 1) ». Une somme dans un produit, elle, en reçoit,
%   parce que sans elles le sens changerait.
%
%   Exemple :
%      x = sym('x');
%      symstr(symmul(symadd(x, symnum(1)), symnum(2)))     % '(x + 1) * 2'
%      symstr(symadd(symmul(x, symnum(2)), symnum(1)))     % 'x*2 + 1'
%
%   Voir aussi SYMSIMPLIFY, SYMSUBS, SYMADD.
    s = matlibre_sym_ecrire(matlibre_sym_arbre(e), 0);
end
