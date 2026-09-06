function e = symfun(nom, argument)
%SYMFUN Application d'une fonction élémentaire.
%   E = SYMFUN(NOM,ARGUMENT) construit l'arbre {NOM, ARGUMENT} : une
%   application de fonction, non son évaluation. ARGUMENT peut être un
%   arbre, un objet SYM, un nombre ou un nom de variable.
%
%   Fonctions reconnues par la dérivation, la simplification et
%   l'écriture : sin, cos, tan, exp, log, sqrt.
%
%   Un noeud d'application n'a qu'un opérande, là où les opérateurs
%   binaires en ont deux : c'est ce qui permet aux parcours de l'arbre de
%   distinguer les deux cas sur le seul nombre d'éléments de la cellule.
%
%   Exemple :
%      x = sym('x');
%      symstr(symfun('sin', x))                 % 'sin(x)'
%      symstr(symsubs(symfun('exp', x), 'x', 0))   % 'exp(0)'
%
%   Voir aussi SYMADD, SYMSIMPLIFY, SYMSTR, SYMDIFF.
    e = {nom, matlibre_sym_arbre(argument)};
end
