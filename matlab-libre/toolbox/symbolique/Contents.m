% Symbolic Math Toolbox — calcul formel.
%
% Une expression est un arbre : {operateur, sous-expression, ...}, les
% feuilles étant des nombres ou des noms de variables. Les fonctions
% ci-dessous manipulent cet arbre.
%
%   symvar, symnum   - Feuilles : variable, constante
%   symadd, symsub, symmul, symdiv, sympow, symfun - Constructeurs
%   symdiff          - Dérivée par rapport à une variable
%   symsimplify      - Simplification des cas triviaux
%   symsubs          - Substitution
%   symeval          - Évaluation numérique
%   symstr           - Écriture lisible
%   symint           - Primitive des formes polynomiales
