% Symbolic Math Toolbox — calcul formel.
%
% Un objet SYM porte une expression ; les opérateurs ordinaires la
% construisent, et les fonctions ci-dessous la manipulent.
%
% Construction
%   sym               - Variable, constante ou expression
%   syms              - Déclaration de plusieurs variables
%   symvar            - Variables d'une expression
%   poly2sym, sym2poly - Passage aux coefficients d'un polynôme
%
% Calcul différentiel et intégral
%   diff              - Dérivée, à un ordre quelconque
%   int               - Primitive, ou intégrale définie
%   limit             - Limite, par extrapolation de Richardson
%   taylor            - Développement de Taylor
%   jacobian, hessian - Dérivées premières et secondes croisées
%   symsum, symprod   - Somme et produit sur un intervalle d'entiers
%
% Algèbre
%   simplify, expand  - Réduction et développement
%   subs              - Substitution
%   solve             - Racines d'une équation polynomiale
%
% Écriture et passage au numérique
%   char, pretty      - Écriture lisible
%   latex             - Écriture LaTeX
%   double, vpa       - Valeur numérique
%   matlabFunction    - Poignée de fonction évaluable
%
% Les fonctions ci-dessous travaillent directement sur l'arbre, pour qui
% le préfère à l'objet. L'arbre est une cellule {operateur,
% sous-expression, ...}, les feuilles étant des nombres ou des noms.
%
%   symvar, symnum   - Feuilles : variable, constante
%   symadd, symsub, symmul, symdiv, sympow, symfun - Constructeurs
%   symdiff          - Dérivée par rapport à une variable
%   symsimplify      - Simplification des cas triviaux
%   symsubs          - Substitution
%   symeval          - Évaluation numérique
%   symstr           - Écriture lisible
%   symint           - Primitive des formes polynomiales
