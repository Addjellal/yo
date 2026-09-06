# Toolbox `symbolique`

```
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
```

## `hessian`

```
HESSIAN Matrice hessienne d'une expression symbolique.
  H = HESSIAN(F,V) rend les dérivées secondes : H{i,j} est la dérivée
  de F par rapport à V{i} puis V{j}.
  H = HESSIAN(F) prend les variables de F, par ordre alphabétique.

  La hessienne est symétrique dès que les dérivées secondes croisées
  sont continues — c'est le théorème de Schwarz —, et le calcul le
  montre.

  Exemple :
     syms x y
     H = hessian(x ^ 2 * y, {x, y});
     char(H{1, 1})                  % '2 * y'
     char(H{1, 2})                  % '2 * x'

  Voir aussi JACOBIAN, GRADIENT, DIFF.
```

## `jacobian`

```
JACOBIAN Matrice jacobienne d'expressions symboliques.
  J = JACOBIAN(F,V) où F est une cellule d'expressions et V une cellule
  de variables : J{i,j} est la dérivée de F{i} par rapport à V{j}.
  Une seule expression donne une ligne, la jacobienne d'une fonction
  scalaire étant son gradient transposé.

  J = JACOBIAN(F) prend pour variables celles qui apparaissent dans F,
  par ordre alphabétique.

  Exemple :
     syms x y
     J = jacobian({x * y, x + y}, {x, y});
     char(J{1, 1})                  % 'y'

  Voir aussi DIFF, GRADIENT, HESSIAN, SYMVAR.
```

## `latex`

```
LATEX Écriture LaTeX d'une expression symbolique.
  S = LATEX(F) rend le code LaTeX de F : les fractions deviennent des
  \frac, les puissances des exposants, les fonctions élémentaires des
  commandes.

  Exemple :
     syms x
     latex((x + 1) / (x ^ 2))       % '\frac{x + 1}{x^{2}}'

  Voir aussi PRETTY, CHAR, SYM.
```

## `limit`

```
LIMIT Limite d'une expression symbolique.
  L = LIMIT(F,X,A) rend la limite de F quand X tend vers A.
  L = LIMIT(F,X,A,'left') ou 'right' prend la limite d'un seul côté.
  L = LIMIT(F) et LIMIT(F,A) sous-entendent la variable.

  La limite est cherchée numériquement, en s'approchant du point par
  pas géométriquement décroissants, puis en accélérant la convergence
  par extrapolation de Richardson. Une substitution directe suffit
  quand elle donne un résultat fini : c'est le cas courant.

  Comptez une dizaine de chiffres exacts sur les limites usuelles ; la
  méthode est numérique, non formelle, et ne prouve rien.

  Exemple :
     syms x
     double(limit(sin(x) / x, x, 0))   % 1
     double(limit((1 + 1/x) ^ x, x, Inf))   % environ e

  Voir aussi TAYLOR, DIFF, SUBS, DOUBLE.
```

## `matlabFunction`

```
MATLABFUNCTION Poignée de fonction à partir d'une expression symbolique.
  F = MATLABFUNCTION(E) rend une poignée qui évalue E numériquement,
  ses arguments étant les variables de E par ordre alphabétique.
  F = MATLABFUNCTION(E,'Vars',{X,Y}) impose l'ordre des arguments.

  C'est le pont entre le calcul formel et le calcul numérique : on
  dérive ou simplifie en symbolique, puis on évalue par milliers.

  Exemple :
     syms x
     f = matlabFunction(diff(x ^ 3));
     f(2)                           % 12

  Voir aussi SYM, DIFF, SUBS, DOUBLE, STR2FUNC.
```

## `matlibre_sym_appliquer`

```
MATLIBRE_SYM_APPLIQUER Applique une fonction élémentaire à une expression.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_sym_arbre`

```
MATLIBRE_SYM_ARBRE L'arbre d'expression d'une valeur quelconque.
  Un objet SYM rend son arbre, un nombre devient une constante, un nom
  une variable, et un arbre se rend tel quel.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_sym_coefficients`

```
MATLIBRE_SYM_COEFFICIENTS Coefficients d'un polynôme en une variable.
  Rendus par puissances décroissantes, comme POLYVAL les attend. Une
  expression qui n'est pas polynomiale en cette variable est refusée
  plutôt que tronquée.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_sym_defaut`

```
MATLIBRE_SYM_DEFAUT La variable qu'on sous-entend dans une expression.
  C'est la plus proche de « x », comme dans MATLAB. Une expression sans
  variable est dérivée par rapport à x, ce qui donne zéro.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_sym_developper`

```
MATLIBRE_SYM_DEVELOPPER Distribue les produits sur les sommes.
  La règle est celle de l'école : a(b+c) devient ab+ac, et une
  puissance entière positive se développe par produits répétés. Le
  développement s'arrête quand plus rien ne change.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_sym_ecrire`

```
MATLIBRE_SYM_ECRIRE Écriture d'une expression, parenthèses minimales.
  PRIORITE est celle du contexte : on n'entoure de parenthèses que ce
  qui lierait moins fort que lui.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_sym_latex`

```
MATLIBRE_SYM_LATEX Écriture LaTeX d'un arbre d'expression.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_sym_limite`

```
MATLIBRE_SYM_LIMITE Limite approchée, par extrapolation de Richardson.
  On évalue l'expression en une suite de points qui s'approchent
  géométriquement, puis on extrapole : la table de Richardson efface
  les termes d'erreur les uns après les autres, ce qu'une simple suite
  de valeurs ne ferait pas.

  Les pas restent volontairement grands — de un demi à deux
  dix-millièmes. Les rétrécir davantage ne rapprocherait pas du
  résultat mais l'éloignerait : (1-cos x)/x^2 en x = 1e-7 se calcule
  sur une différence de deux nombres presque égaux, et il ne reste
  plus un chiffre juste. C'est l'extrapolation qui fait le travail,
  pas la petitesse du pas.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_sym_nom`

```
MATLIBRE_SYM_NOM Le nom d'une variable donnée comme SYM, texte ou arbre.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_sym_noms`

```
MATLIBRE_SYM_NOMS Noms des variables d'un arbre d'expression.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_sym_polynome`

```
MATLIBRE_SYM_POLYNOME Arbre d'un polynôme donné par ses coefficients.
  Les coefficients vont par puissances décroissantes. Les termes nuls
  sont omis, les coefficients un ne sont pas écrits, et un coefficient
  négatif donne une soustraction plutôt qu'une addition de nombre
  négatif : « x^2 - 1 » au lieu de « x^2 + -1 ».

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_sym_proches`

```
MATLIBRE_SYM_PROCHES Les variables les plus proches de « x ».
  La règle est celle de MATLAB : on classe par distance à la lettre x
  dans l'alphabet, les lettres qui la suivent passant avant celles qui
  la précèdent à distance égale. C'est ce qui fait que DIFF(a*x^2)
  dérive par rapport à x, non à a.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_sym_reduire`

```
MATLIBRE_SYM_REDUIRE Simplifie, et regroupe les termes semblables.
  Après la simplification des cas triviaux, on essaie de lire
  l'expression comme un polynôme en sa variable : si elle en est un,
  on la réécrit à partir de ses coefficients, ce qui regroupe les
  termes semblables et efface les zéros. Sinon on garde la forme
  simplifiée.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_sym_valeur`

```
MATLIBRE_SYM_VALEUR La valeur numérique d'un SYM, d'un nombre ou d'un
  arbre constant.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_sym_variable`

```
MATLIBRE_SYM_VARIABLE Feuille « variable » d'un arbre d'expression.
  C'est le constructeur de bas niveau, celui qu'emploient SYMDIFF,
  SYMINT et leurs voisines. SYM('x') fait la même chose et rend un
  objet ; SYMVAR, lui, porte le sens de MATLAB — les variables d'une
  expression.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `poly2sym`

```
POLY2SYM Expression symbolique d'un polynôme donné par ses coefficients.
  F = POLY2SYM(P) où P porte les coefficients par puissances
  décroissantes, comme POLYVAL les attend ; la variable est x.
  F = POLY2SYM(P,X) nomme la variable.

  C'est l'inverse de SYM2POLY : ensemble, elles font passer d'une
  écriture à l'autre.

  Exemple :
     f = poly2sym([1 0 -4]);
     char(f)                        % '((x ^ 2) - 4)'
     sym2poly(f)                    % [1 0 -4]

  Voir aussi SYM2POLY, SYM, ROOTS, POLYVAL.
```

## `pretty`

```
PRETTY Écriture lisible d'une expression symbolique.
  PRETTY(F) affiche F sans les parenthèses que la priorité des
  opérateurs rend inutiles.
  S = PRETTY(F) rend le texte au lieu de l'afficher.

  Exemple :
     syms x
     pretty(x ^ 2 + 3 * x - 1)      % x^2 + 3*x - 1

  Voir aussi SYM, CHAR, LATEX, DISP.
```

## `sym`

```
SYM Expression symbolique.
  X = SYM('x') crée la variable symbolique x.
  A = SYM(3) crée la constante 3.
  Les opérateurs ordinaires construisent alors des expressions :
  X^2 + 3*X - 1 en est une, et DIFF, INT, SUBS, SIMPLIFY et SOLVE les
  manipulent.

  Un calcul symbolique diffère d'un calcul numérique en ce qu'il garde
  la forme : la dérivée de sin(x) est cos(x), non une suite de valeurs.
  C'est ce qui permet de simplifier, de résoudre, ou de relire.

  L'expression est un arbre — opérateur puis sous-expressions — rangé
  dans la propriété « arbre » ; les fonctions SYMADD, SYMDIFF et leurs
  voisines travaillent directement dessus, quand on préfère l'arbre à
  l'objet.

  Exemple :
     x = sym('x');
     f = x ^ 3 - 2 * x;
     diff(f)                        % 3*x^2 - 2
     double(subs(f, x, 2))          % 4
     solve(x ^ 2 - 4)               % -2 et 2

  Voir aussi SYMS, DIFF, INT, SUBS, SIMPLIFY, SOLVE, DOUBLE.
```

## `symadd`

```
SYMADD Somme de deux expressions.
  E = SYMADD(A,B) construit l'arbre {'+', A, B} sans rien
  évaluer.

  Les expressions se représentent par des arbres, sous forme de
  cellules : le premier élément est l'opérateur, les suivants ses
  opérandes. C'est la représentation la plus simple qui permette de
  dériver, de substituer et de simplifier sans jamais évaluer.

  Ces constructeurs ne calculent rien : ils assemblent. C'est
  SYMSIMPLIFY qui réduit, SYMSUBS qui substitue et SYMSTR qui écrit.

  Exemple :
     x = sym('x');
     symstr(symsimplify(symadd(symnum(0), x)))

  Voir aussi SYMSIMPLIFY, SYMSTR, SYMSUBS, SYMNUM.
```

## `symdiff`

```
SYMDIFF Dérivée symbolique d'une expression.
  D = SYMDIFF(E,'x') applique les règles usuelles : somme, produit,
  quotient, puissance et composition des fonctions élémentaires.
```

## `symdiv`

```
SYMDIV Quotient de deux expressions.
  E = SYMDIV(A,B) construit l'arbre {'/', A, B} sans rien
  évaluer.

  Les expressions se représentent par des arbres, sous forme de
  cellules : le premier élément est l'opérateur, les suivants ses
  opérandes. C'est la représentation la plus simple qui permette de
  dériver, de substituer et de simplifier sans jamais évaluer.

  Ces constructeurs ne calculent rien : ils assemblent. C'est
  SYMSIMPLIFY qui réduit, SYMSUBS qui substitue et SYMSTR qui écrit.

  Exemple :
     x = sym('x');
     symstr(symsimplify(symdiv(x, symnum(1))))

  Voir aussi SYMSIMPLIFY, SYMSTR, SYMSUBS, SYMNUM.
```

## `symeval`

```
SYMEVAL Évaluation numérique d'une expression.
  V = SYMEVAL(E,{'x','y'},[1 2]) remplace puis calcule.
```

## `symfun`

```
SYMFUN Application d'une fonction élémentaire.
  Fonctions reconnues : sin, cos, tan, exp, log, sqrt.
```

## `symint`

```
SYMINT Primitive des formes polynomiales et élémentaires.
  Reconnaît les constantes, x^n, sin, cos, exp et les sommes.
```

## `symmul`

```
SYMMUL Produit de deux expressions.
  E = SYMMUL(A,B) construit l'arbre {'*', A, B} sans rien
  évaluer.

  Les expressions se représentent par des arbres, sous forme de
  cellules : le premier élément est l'opérateur, les suivants ses
  opérandes. C'est la représentation la plus simple qui permette de
  dériver, de substituer et de simplifier sans jamais évaluer.

  Ces constructeurs ne calculent rien : ils assemblent. C'est
  SYMSIMPLIFY qui réduit, SYMSUBS qui substitue et SYMSTR qui écrit.

  Exemple :
     x = sym('x');
     symstr(symsimplify(symmul(symnum(1), x)))

  Voir aussi SYMSIMPLIFY, SYMSTR, SYMSUBS, SYMNUM.
```

## `symnum`

```
SYMNUM Feuille « constante ».
  E = SYMNUM(VALEUR) construit la feuille {'num', VALEUR} : c'est ainsi
  qu'un nombre entre dans une expression symbolique.

  Sans elle, un nombre nu ne se distinguerait pas d'un opérateur dans
  l'arbre. Les constructeurs qui acceptent un nombre l'enveloppent
  d'eux-mêmes.

  Exemple :
     symstr(symadd(symnum(2), symnum(3)))    % '2 + 3', non '5'
     symstr(symsimplify(symadd(symnum(2), symnum(3))))   % '5'

  Voir aussi SYMADD, SYMSIMPLIFY, SYMSTR.
```

## `sympow`

```
SYMPOW Puissance : A élevé à B.
  E = SYMPOW(A,B) construit l'arbre {'^', A, B} sans rien
  évaluer.

  Les expressions se représentent par des arbres, sous forme de
  cellules : le premier élément est l'opérateur, les suivants ses
  opérandes. C'est la représentation la plus simple qui permette de
  dériver, de substituer et de simplifier sans jamais évaluer.

  Ces constructeurs ne calculent rien : ils assemblent. C'est
  SYMSIMPLIFY qui réduit, SYMSUBS qui substitue et SYMSTR qui écrit.

  Exemple :
     x = sym('x');
     symstr(symsimplify(sympow(x, symnum(1))))

  Voir aussi SYMSIMPLIFY, SYMSTR, SYMSUBS, SYMNUM.
```

## `symprod`

```
SYMPROD Produit d'une expression symbolique sur un intervalle d'entiers.
  P = SYMPROD(F,K,A,B) multiplie F pour K allant de A à B, bornes
  comprises. Comme SYMSUM, le calcul est terme à terme.
  P = SYMPROD(F,A,B) sous-entend la variable.

  Exemple :
     syms k
     double(symprod(k, k, 1, 6))    % 720 : la factorielle de six

  Voir aussi SYMSUM, PROD, FACTORIAL.
```

## `syms`

```
SYMS Déclare des variables symboliques.
  SYMS X Y Z crée dans l'espace de travail appelant les variables
  symboliques nommées, comme si l'on avait écrit X = SYM('X') pour
  chacune.

  C'est un raccourci : tout ce qu'il fait, SYM le fait aussi, mais une
  ligne suffit alors pour dix variables.

  Exemple :
     syms x y
     f = x ^ 2 + y ^ 2;
     diff(f, x)                     % 2*x

  Voir aussi SYM, SYMVAR, DIFF, SUBS.
```

## `symsimplify`

```
SYMSIMPLIFY Simplification des cas triviaux.
  S = SYMSIMPLIFY(E) réduit ce qui se réduit sans ruse : les constantes
  se calculent, l'addition de zéro et la multiplication par un
  disparaissent, la multiplication par zéro annule, la puissance zéro
  ou un se résout.

  Elle ne factorise pas, ne développe pas et ne reconnaît pas les
  identités remarquables : la simplification symbolique complète est un
  problème difficile, et une simplification partielle honnête vaut mieux
  qu'une simplification approximative.

  Elle est appliquée récursivement, des feuilles vers la racine : une
  simplification en profondeur peut donc en déclencher une au-dessus.

  Exemple :
     x = sym('x');
     symstr(symsimplify(symmul(symnum(1), x)))           % 'x'
     symstr(symsimplify(symadd(symnum(2), symnum(3))))   % '5'
     symstr(symsimplify(symmul(symnum(0), x)))           % '0'

  Voir aussi SYMSTR, SYMSUBS, SIMPLIFY.
```

## `symstr`

```
SYMSTR Écriture lisible d'une expression symbolique.
  S = SYMSTR(E) rend l'expression sous forme de texte, avec les
  parenthèses qu'impose la priorité des opérateurs — ni plus ni moins.

  C'est la seule fonction qui regarde l'arbre pour le rendre à un
  lecteur : toutes les autres le transforment. Un arbre non simplifié
  s'écrit tel quel, ce qui permet de voir ce que SYMSIMPLIFY a fait.

  Exemple :
     x = sym('x');
     symstr(symmul(symadd(x, symnum(1)), symnum(2)))     % '(x + 1) * 2'

  Voir aussi SYMSIMPLIFY, SYMSUBS, SYMADD.
```

## `symsub`

```
SYMSUB Différence de deux expressions.
  E = SYMSUB(A,B) construit l'arbre {'-', A, B} sans rien
  évaluer.

  Les expressions se représentent par des arbres, sous forme de
  cellules : le premier élément est l'opérateur, les suivants ses
  opérandes. C'est la représentation la plus simple qui permette de
  dériver, de substituer et de simplifier sans jamais évaluer.

  Ces constructeurs ne calculent rien : ils assemblent. C'est
  SYMSIMPLIFY qui réduit, SYMSUBS qui substitue et SYMSTR qui écrit.

  Exemple :
     x = sym('x');
     symstr(symsimplify(symsub(x, x)))

  Voir aussi SYMSIMPLIFY, SYMSTR, SYMSUBS, SYMNUM.
```

## `symsubs`

```
SYMSUBS Substitution d'une variable par une expression ou un nombre.
  R = SYMSUBS(E,VARIABLE,VALEUR) remplace toutes les occurrences de la
  variable nommée par VALEUR, qui peut être un nombre ou une autre
  expression.

  La substitution ne simplifie pas : remplacer x par 2 dans x + x donne
  « 2 + 2 », non « 4 ». C'est voulu — SYMSIMPLIFY fait ce travail, et
  les séparer permet de voir ce que chaque étape produit.

  Substituer une expression, non un nombre, est ce qui permet de
  composer des fonctions symboliquement.

  Exemple :
     x = sym('x');
     symstr(symsubs(symadd(x, x), 'x', 2))       % '2 + 2'
     symstr(symsimplify(symsubs(symadd(x, x), 'x', 2)))   % '4'

  Voir aussi SYMSIMPLIFY, SYMSTR, SUBS.
```

## `symsum`

```
SYMSUM Somme d'une expression symbolique sur un intervalle d'entiers.
  S = SYMSUM(F,K,A,B) additionne F pour K allant de A à B, bornes
  comprises. A et B doivent être des entiers finis : la somme est
  calculée terme à terme, non par une formule fermée.
  S = SYMSUM(F,A,B) sous-entend la variable.

  Exemple :
     syms k
     double(symsum(k, k, 1, 100))   % 5050
     double(symsum(1 / k ^ 2, k, 1, 1000))   % environ pi^2/6

  Voir aussi SYMPROD, INT, SUBS, SUM.
```

## `symvar`

```
SYMVAR Variables d'une expression symbolique.
  V = SYMVAR(F) rend, dans un tableau de SYM, les variables qui
  apparaissent dans F, rangées par ordre alphabétique.
  V = SYMVAR(F,N) n'en rend que N, choisies au plus près de « x » :
  c'est la règle de MATLAB pour deviner la variable d'une dérivation
  ou d'une résolution quand on ne la nomme pas.

  Exemple :
     syms a x
     symvar(a * x ^ 2)              % [a, x]
     char(symvar(a * x ^ 2, 1))     % 'x' : la plus proche de x

  Voir aussi SYM, SYMS, DIFF, SOLVE.
```

## `taylor`

```
TAYLOR Développement de Taylor d'une expression symbolique.
  T = TAYLOR(F) développe F autour de zéro jusqu'au degré cinq.
  T = TAYLOR(F,X) nomme la variable, TAYLOR(F,X,A) choisit le point,
  TAYLOR(F,X,A,N) le nombre de termes — le développement va alors
  jusqu'au degré N-1, comme dans MATLAB.

  Les coefficients viennent des dérivées successives évaluées au
  point : c'est la définition, non une table.

  Exemple :
     syms x
     pretty(taylor(exp(x), x, 0, 4))   % 1 + x + x^2/2 + x^3/6
     pretty(taylor(sin(x), x, 0, 6))

  Voir aussi DIFF, SUBS, SIMPLIFY, LIMIT.
```

## `vpa`

```
VPA Évaluation numérique d'une expression symbolique.
  V = VPA(E) évalue E et rend le résultat, arrondi à trente-deux
  chiffres — la précision par défaut de MATLAB.
  V = VPA(E,N) arrondit à N chiffres significatifs.

  MATLAB calcule ici en précision variable, avec autant de chiffres
  qu'on lui en demande. MatLibre n'a que le flottant double : il évalue
  donc en double précision puis arrondit à N chiffres, ce qui est
  fidèle jusqu'à quinze chiffres et ne l'est plus au delà. Demander
  trente-deux chiffres n'en donne pas trente-deux justes.

  Le résultat est rendu sous forme de SYM, comme dans MATLAB ; DOUBLE
  en tire le nombre.

  Exemple :
     syms x
     double(vpa(subs(x ^ 2, x, sqrt(2))))   % 2
     char(vpa(sym(1) / 3, 6))               % '0.333333'

  Voir aussi DOUBLE, SYM, SUBS, DIGITS.
```

