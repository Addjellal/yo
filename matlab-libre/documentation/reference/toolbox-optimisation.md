# Toolbox `optimisation`

```
% Optimization Toolbox — optimisation sous contraintes.
%
% Programmation linéaire et quadratique
%   linprog     - Minimise f'x sous contraintes linéaires
%   quadprog    - Minimise une forme quadratique
%   intlinprog  - Variables entières, par séparation et évaluation
%   bintprog    - Variables binaires
%
% Programmation conique
%   secondordercone - Contrainte ||A*x-b|| <= d'x - gamma
%   coneprog        - Minimise une forme linéaire sur des cônes
%
% Optimisation non linéaire
%   fmincon     - Minimisation sous contraintes
%   fminimax    - Minimise le pire des critères
%
% Moindres carrés
%   lsqlin      - Moindres carrés linéaires sous contraintes
%   lsqcurvefit - Ajustement de courbe
%   lsqnonlin   - Moindres carrés non linéaires (Levenberg-Marquardt)
%
% Écriture par problème
%   optimvar     - Variable nommée, bornée, éventuellement entière
%   optimexpr    - Expression linéaire ou quadratique de variables
%   optimconstr  - Contrainte née d'une comparaison d'expressions
%   optimproblem - Problème : objectif, sens et contraintes nommées
%   prob2struct  - Traduit le problème en matrices pour les solveurs
%   solve        - Résout, en choisissant le solveur selon la forme
%
% Réglages
%   optimoptions - Options d'un solveur, noms modernes et anciens
%
% Les fonctions natives fminsearch, fminbnd, fminunc, fsolve, fzero et
% lsqnonneg complètent l'ensemble.
%
% Objectifs multiples et contraintes semi-infinies
%   fgoalattain - Atteinte d'objectifs pondérés
%   fseminf     - Contraintes valables pour tout un intervalle
```

## `bintprog`

```
BINTPROG Programmation linéaire en variables binaires, par énumération.
  X = BINTPROG(F,A,B) minimise f'*x sous A*x <= b, x dans {0,1}^n.
  L'énumération est exhaustive : à réserver aux petits problèmes.
  Vingt-deux variables au plus — au-delà, l'appel est refusé plutôt
  que laissé tourner ; INTLINPROG, qui coupe l'arbre, prend le relais.

  [X,VAL] = BINTPROG(...) rend aussi la valeur atteinte.

  Exemple :
     % Un sac à dos : deux objets de valeurs 1 et 2, une seule place.
     [x, val] = bintprog([-1; -2], [1 1], 1);
     x                              % [0; 1] : on prend le meilleur
     val                            % -2

  Voir aussi INTLINPROG, LINPROG, QUADPROG, OPTIMPROBLEM.
```

## `coneprog`

```
CONEPROG Programmation sur cône du second ordre.
  X = CONEPROG(F,CONES) minimise F'*X sous les contraintes de cône
  décrites par SECONDORDERCONE : chacune impose ||A*x - b|| <= d'x - g.
  X = CONEPROG(F,CONES,A,B,AEQ,BEQ,LB,UB) ajoute les contraintes
  linéaires et les bornes.

  Le cône du second ordre couvre bien plus que la programmation
  linéaire : une contrainte sur la norme d'un vecteur, un compromis
  entre coût et risque, une distance minimale, s'y écrivent
  directement — et le problème reste convexe.

  [X,VAL,DRAPEAU] = CONEPROG(...) rend la valeur et l'état.

  MATLAB emploie un algorithme de point intérieur propre aux cônes ;
  MatLibre traite la contrainte de cône comme une contrainte non
  linéaire ordinaire et passe par FMINCON. La solution est la même à la
  précision près, la convergence est plus lente.

  Exemple :
     % Le point du disque unité le plus loin dans la direction (1,1)
     c = secondordercone(eye(2), [0; 0], [0; 0], -1);
     x = coneprog([-1; -1], c);

  Voir aussi SECONDORDERCONE, QUADPROG, LINPROG, FMINCON.
```

## `fgoalattain`

```
FGOALATTAIN Atteinte d'objectifs multiples.
  X = FGOALATTAIN(F,X0,BUTS,POIDS) cherche X et un facteur GAMMA aussi
  petit que possible tels que

     F(X) - POIDS * GAMMA <= BUTS.

  Un GAMMA négatif signifie que tous les buts sont dépassés, un GAMMA
  positif qu'on reste en deçà, proportionnellement aux poids.

  [X,F,GAMMA] = FGOALATTAIN(...) rend aussi le facteur atteint.

  Exemple :
     f = @(x) [x(1)^2, (x(1)-2)^2];
     [x, v, g] = fgoalattain(f, 0, [1 1], [1 1]);

  Voir aussi FMINIMAX, FMINCON, FSEMINF, OPTIMOPTIONS.
```

## `fmincon`

```
FMINCON Minimisation sous contraintes, par pénalisation extérieure.
  X = FMINCON(F,X0,A,B) minimise F sous A*x <= b.
  X = FMINCON(F,X0,A,B,AEQ,BEQ,LB,UB,NONLIN) ajoute les égalités, les
  bornes et les contraintes non linéaires : NONLIN rend [c, ceq], avec
  c <= 0 et ceq == 0.

  [X,VAL] = FMINCON(...) rend aussi la valeur atteinte.

  La méthode est la pénalisation extérieure : on minimise le critère
  augmenté du carré des violations, avec un poids qu'on multiplie par
  quatre à chaque tour. La solution s'approche donc de la frontière
  par l'extérieur, et une contrainte peut rester violée d'un
  millième.

  Exemple :
     % Le point du demi-plan x+y >= 2 le plus proche de l'origine :
     % c'est (1,1), sur la frontière.
     f = @(v) v(1)^2 + v(2)^2;
     x = fmincon(f, [2; 0], [-1 -1], -2);
     round(x, 2)                    % [1; 1]

  Voir aussi FMINUNC, FMINSEARCH, LINPROG, QUADPROG, CONEPROG,
  FMINIMAX, OPTIMOPTIONS.
```

## `fminimax`

```
FMINIMAX Minimise le maximum d'un ensemble de fonctions.
  X = FMINIMAX(F,X0) où F(x) rend un vecteur : on minimise max(F(x)).
  C'est le critère du pire cas : on ne cherche pas la meilleure moyenne
  mais la plus petite des plus grandes valeurs, ce qui protège du
  critère le plus mal servi.

  [X,VAL] = FMINIMAX(...) rend en outre la valeur atteinte par ce
  maximum.

  Exemple :
     % Deux droites qui se croisent : le maximum est le plus bas là
     % où elles se coupent, en x = 1.
     f = @(x) [x - 1; 1 - x];
     x = fminimax(f, 0)             % 1

  Voir aussi FMINCON, FGOALATTAIN, FMINSEARCH, LSQNONLIN.
```

## `fseminf`

```
FSEMINF Minimisation sous contraintes semi-infinies.
  X = FSEMINF(F,X0,NTHETA,SEMI) minimise F sous des contraintes qui
  doivent tenir pour toute valeur d'un paramètre continu : SEMI rend
  les contraintes évaluées sur un échantillonnage du paramètre.

  SEMI a la forme [C, CEQ, K1, K2, ..., S] = SEMI(X, S) : les K sont
  les contraintes semi-infinies échantillonnées, S le pas
  d'échantillonnage.

  L'implémentation discrétise le paramètre puis résout le problème
  ordinaire qui en résulte, en resserrant l'échantillonnage tant que
  la pire violation diminue.

  Exemple :
     f = @(x) x(1)^2;
     s = @(x, s) deal([], [], x(1) - (0:0.05:1)' - 0.2, s);
     x = fseminf(f, 1, 1, s);

  Voir aussi FMINCON, FMINIMAX, FGOALATTAIN, OPTIMOPTIONS.
```

## `intlinprog`

```
INTLINPROG Programmation linéaire en nombres entiers.
  X = INTLINPROG(F,INTCON,A,B,AEQ,BEQ,LB,UB) minimise F'*X sous
  A*X <= B et AEQ*X = BEQ, les variables d'indices INTCON étant
  entières.

  La résolution se fait par séparation et évaluation : on résout la
  relaxation continue, puis on scinde sur une variable fractionnaire.
  C'est exact, au prix d'un arbre qui peut grandir.

  Exemple :
     x = intlinprog([-1; -2], [1 2], [1 1], 4, [], [], [0; 0], []);

  Voir aussi LINPROG, QUADPROG, BINTPROG, OPTIMPROBLEM, SOLVE.
```

## `linprog`

```
LINPROG Programmation linéaire : minimise f'*x sous A*x <= b.
  [X,VAL] = LINPROG(F,A,B) résout le problème par une méthode de
  pénalisation intérieure : on minimise f'x - mu*sum(log(b - Ax)) pour
  une suite décroissante de mu, ce qui converge vers l'optimum du
  problème contraint.

  [X,VAL] = LINPROG(F,A,B,AEQ,BEQ,LB,UB) ajoute les contraintes
  d'égalité, traitées par pénalisation quadratique, et les bornes. Une
  borne infinie est reconnue comme telle : elle ne contraint rien.

  Exemple :
     % Deux ressources, deux produits : on maximise 1*x + 2*y, donc on
     % minimise l'opposé.
     [x, val] = linprog([-1; -2], [1 1; 1 3], [4; 6], [], [], [0; 0], []);
     x                              % [3; 1]
     val                            % -5

  Voir aussi QUADPROG, INTLINPROG, CONEPROG, LSQLIN, OPTIMPROBLEM.
```

## `lsqcurvefit`

_Pas de bloc d'aide._

## `lsqlin`

```
LSQLIN Moindres carrés linéaires avec contraintes de bornes.
  X = LSQLIN(C,D) minimise ||C*x - d||.
  X = LSQLIN(C,D,A,B,AEQ,BEQ,LB,UB) impose A*x <= b, Aeq*x = beq et les
  bornes. Sans contrainte, la solution est celle de C\D ; les
  contraintes sont ce qui distingue LSQLIN de l'antislash.

  Exemple :
     % Le moindres carrés ordinaire, puis le même borné par le haut.
     C = [1 0; 0 1; 1 1];
     d = [1; 2; 4];
     x = lsqlin(C, d);
     round(x, 3)
     borne = lsqlin(C, d, [], [], [], [], [], [1; 1]);
     round(borne, 3)                % chaque terme au plus 1

  Voir aussi LSQNONNEG, LSQNONLIN, LINPROG, QUADPROG, MLDIVIDE.
```

## `lsqnonlin`

```
LSQNONLIN Moindres carrés non linéaires.
  X = LSQNONLIN(F,X0) minimise la somme des carrés des composantes de
  F(X). LSQNONLIN(F,X0,LB,UB) impose des bornes.

  La méthode est celle de Levenberg-Marquardt : le jacobien est estimé
  par différences finies, et l'amortissement passe de la descente de
  gradient à Gauss-Newton selon que le pas améliore ou non le critère.

  Exemple :
     % Ajustement de a*exp(b*t) sur des données exactes.
     t = (0:0.5:2)';  y = 3 * exp(-0.5 * t);
     p = lsqnonlin(@(p) p(1) * exp(p(2) * t) - y, [1; -1]);

  Voir aussi LSQCURVEFIT, LSQLIN, FSOLVE, FMINSEARCH.
```

## `matlibre_bornes_en_contraintes`

```
MATLIBRE_BORNES_EN_CONTRAINTES Ajoute les bornes aux inégalités.
  Une borne inférieure x >= bas s'écrit -x <= -bas ; une borne
  supérieure s'écrit telle quelle. Les bornes infinies sont ignorées.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_definie_positive`

```
MATLIBRE_DEFINIE_POSITIVE La matrice est-elle symétrique définie positive ?
  La factorisation de Cholesky échoue exactement dans le cas contraire ;
  c'est le test le moins coûteux et le plus sûr.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_jacobienne_residu`

```
MATLIBRE_JACOBIENNE_RESIDU Jacobienne d'un vecteur de résidus.
  J = MATLIBRE_JACOBIENNE_RESIDU(FONCTION,P,RESIDU) rend la matrice des
  dérivées de chaque résidu par rapport à chaque paramètre, par
  différence centrée. C'est elle qui donne la covariance des paramètres
  ajustés, donc leurs intervalles de confiance.

  Exemple :
     J = matlibre_jacobienne_residu(@(p) p(1) * [1; 2], 1, [1; 2]);
     J      % [1; 2]

  Voir aussi LSQCURVEFIT, LSQNONLIN, NLPARCI.
```

## `matlibre_lp_exact`

```
MATLIBRE_LP_EXACT Programme linéaire résolu par régularisation quadratique.
  Un programme linéaire atteint son optimum sur un sommet du polyèdre,
  où une méthode de point intérieur ne se rend jamais tout à fait :
  elle en approche sans l'atteindre. En ajoutant un terme quadratique
  minuscule au critère, le problème devient un programme quadratique
  strictement convexe, que la méthode des contraintes actives résout
  exactement. Le terme est ensuite réduit tant que le critère linéaire
  continue de s'améliorer : à la limite, la solution est le sommet.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_multiplicateurs_bornes`

```
MATLIBRE_MULTIPLICATEURS_BORNES Bornes actives au point trouvé.
  M = MATLIBRE_MULTIPLICATEURS_BORNES(P,BAS,HAUT) rend une structure de
  deux champs, « lower » et « upper », valant un là où la solution
  touche la borne et zéro ailleurs.

  Un multiplicateur non nul signale que la borne retient la solution :
  sans elle, le critère continuerait de décroître dans cette direction.

  Exemple :
     matlibre_multiplicateurs_bornes([0; 5], [0; -inf], []).lower

  Voir aussi LSQCURVEFIT, LSQNONLIN.
```

## `matlibre_qp_actif`

```
MATLIBRE_QP_ACTIF Programme quadratique convexe, par contraintes actives.
  Minimise 0,5*x'Hx + f'x sous A*x <= b et Aeq*x = beq, H étant définie
  positive.

  La méthode tient en une remarque : à l'optimum, chaque contrainte
  d'inégalité est soit saturée, soit sans effet. Si l'on savait
  lesquelles sont saturées, il ne resterait qu'un problème à
  contraintes d'égalité, que les conditions de Lagrange résolvent d'un
  seul système linéaire. On devine donc cet ensemble, on résout, et
  l'on corrige : une contrainte violée y entre, une contrainte dont le
  multiplicateur est négatif en sort. Le nombre d'ensembles étant fini
  et le critère décroissant, le procédé s'arrête.

  REUSSI vaut faux quand le système devient singulier : l'appelant
  revient alors à une méthode moins exigeante.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `optimconstr`

```
OPTIMCONSTR Contrainte d'un problème d'optimisation.
  Une contrainte naît d'une comparaison entre expressions : x + y <= 4
  en est une. Elle garde l'expression ramenée à zéro et le sens de la
  comparaison.

  On ne l'écrit pas à la main : les opérateurs <=, >= et == la
  fabriquent.

  Exemple :
     x = optimvar('x', 2);
     c = sum(x) <= 4;

  Voir aussi OPTIMVAR, OPTIMPROBLEM, SOLVE.
```

## `optimexpr`

```
OPTIMEXPR Expression linéaire ou quadratique de variables d'optimisation.
  Un OPTIMEXPR naît d'un calcul sur des OPTIMVAR : 3*x + 2*y - 1 en est
  un. Il garde le coefficient de chaque variable, les termes croisés
  s'il y en a, et la constante — de quoi assembler, le moment venu, les
  matrices que le solveur attend.

  On ne l'écrit pas à la main : OPTIMVAR et les opérateurs le
  fabriquent.

  Exemple :
     x = optimvar('x', 3);
     e = sum(x) + 2;          % un optimexpr

  Voir aussi OPTIMVAR, OPTIMPROBLEM, OPTIMCONSTR, SOLVE.
```

## `optimoptions`

```
OPTIMOPTIONS Options d'un solveur d'optimisation.
  OPTIONS = OPTIMOPTIONS('fmincon','Display','iter','MaxIterations',100)
  rend une structure d'options. Les noms modernes et les anciens sont
  acceptés, en écriture comme en lecture : MaxIterations ou MaxIter,
  MaxFunctionEvaluations ou MaxFunEvals, OptimalityTolerance ou TolFun,
  StepTolerance ou TolX, ConstraintTolerance ou TolCon. La structure
  rendue porte les deux orthographes, tenues égales : le code écrit
  pour l'une ou pour l'autre lit la même valeur.

  Exemple :
     o = optimoptions('fmincon', 'MaxIterations', 100);
     o.MaxIterations                % 100
     ancien = optimoptions('fminunc', 'TolFun', 1e-8);
     ancien.OptimalityTolerance     % 1e-8 : les deux noms se rejoignent

  Voir aussi OPTIMSET, OPTIMGET, FMINCON, LINPROG, LSQNONLIN.
```

## `optimproblem`

```
OPTIMPROBLEM Problème d'optimisation décrit par ses expressions.
  PROB = OPTIMPROBLEM crée un problème vide, à minimiser.
  PROB = OPTIMPROBLEM('Objective',E) donne l'objectif,
  OPTIMPROBLEM('ObjectiveSense','maximize') le sens.

  Les contraintes s'ajoutent par leur nom :
     prob.Constraints.budget = sum(x) <= 100;

  SOLVE résout le problème, PROB2STRUCT rend les matrices que les
  solveurs classiques attendent.

  Cette écriture dit ce qu'on veut plutôt que comment le ranger : les
  matrices A, b, Aeq, beq sont assemblées pour vous, dans le bon ordre.

  Exemple :
     x = optimvar('x', 2, 'LowerBound', 0);
     prob = optimproblem('Objective', -x(1) - 2*x(2));
     prob.Constraints.c1 = x(1) + x(2) <= 4;
     prob.Constraints.c2 = x(1) + 3*x(2) <= 6;
     sol = solve(prob);
     sol.x

  Voir aussi OPTIMVAR, SOLVE, PROB2STRUCT, LINPROG, QUADPROG, INTLINPROG.
```

## `optimvar`

```
OPTIMVAR Variable d'un problème d'optimisation.
  X = OPTIMVAR('x') crée une variable scalaire nommée x.
  X = OPTIMVAR('x',N) crée un vecteur de N variables.
  X = OPTIMVAR('x',N,'LowerBound',0,'UpperBound',10) les borne.
  X = OPTIMVAR('x',N,'Type','integer') les rend entières.

  Une variable ne porte aucune valeur : elle sert à écrire le problème.
  Les opérateurs +, -, * et SUM fabriquent des expressions, et les
  comparaisons des contraintes. C'est l'écriture « par problème » de
  MATLAB, où l'on décrit ce qu'on veut au lieu d'assembler des
  matrices.

  Exemple :
     x = optimvar('x', 2, 'LowerBound', 0);
     prob = optimproblem('Objective', -x(1) - 2*x(2));
     prob.Constraints.c = x(1) + x(2) <= 4;
     sol = solve(prob);

  Voir aussi OPTIMPROBLEM, OPTIMEXPR, SOLVE, PROB2STRUCT, LINPROG.
```

## `prob2struct`

```
PROB2STRUCT Traduit un problème en matrices pour les solveurs.
  S = PROB2STRUCT(PROB) rend une structure portant f, H, Aineq, bineq,
  Aeq, beq, lb, ub, intcon, solver et objectivesense : ce que LINPROG,
  QUADPROG ou INTLINPROG attendent.

  C'est le passage de l'écriture par expressions à l'écriture par
  matrices ; SOLVE l'emploie, et l'on peut s'en servir pour voir
  exactement ce que le solveur reçoit.

  La structure porte en outre « variables », la liste des variables
  dans l'ordre où elles sont empilées : c'est ce qui permet de relire
  la solution.

  Exemple :
     x = optimvar('x', 2, 'LowerBound', 0);
     prob = optimproblem('Objective', x(1) + x(2));
     s = prob2struct(prob);
     s.f

  Voir aussi OPTIMPROBLEM, OPTIMVAR, SOLVE, LINPROG.
```

## `quadprog`

```
QUADPROG Programmation quadratique : minimise 0.5*x'Hx + f'x.
  X = QUADPROG(H,F) minimise sans contrainte : c'est -H\F.
  X = QUADPROG(H,F,A,B,AEQ,BEQ,LB,UB) impose A*x <= b, Aeq*x = beq et
  les bornes.

  Les contraintes d'inégalité et les bornes sont traitées par
  pénalisation ; le minimum est cherché par Nelder-Mead à partir de la
  solution non contrainte.

  Exemple :
     % Le point le plus proche de [1;1], puis le même sous x1+x2 <= 1.
     x = quadprog(2 * eye(2), [-2; -2]);
     round(x, 3)                    % [1; 1]
     borne = quadprog(2 * eye(2), [-2; -2], [1 1], 1);
     round(sum(borne), 3)           % 1 : la contrainte est saturée

  Voir aussi LINPROG, INTLINPROG, CONEPROG, LSQLIN, FMINCON.
```

## `secondordercone`

```
SECONDORDERCONE Contrainte de cône du second ordre.
  C = SECONDORDERCONE(A,B,D,GAMMA) décrit la contrainte

     ||A*x - B|| <= D'*x - GAMMA,

  c'est-à-dire l'appartenance au cône du second ordre. Elle contient
  comme cas particuliers la boule (D nul), le demi-espace (A nul) et la
  contrainte de norme d'un vecteur d'écarts.

  CONEPROG minimise une forme linéaire sous de telles contraintes.

  Exemple :
     c = secondordercone(eye(2), [0; 0], [0; 0], -1);   % ||x|| <= 1

  Voir aussi CONEPROG, QUADPROG, FMINCON, OPTIMPROBLEM.
```

## `solve`

```
SOLVE Résout un problème écrit par expressions.
  SOL = SOLVE(PROB) choisit le solveur d'après la forme du problème —
  LINPROG pour un objectif linéaire, QUADPROG pour un objectif
  quadratique, INTLINPROG dès qu'une variable est entière — et rend une
  structure portant la valeur de chaque variable.

  [SOL,VAL,DRAPEAU] = SOLVE(PROB) rend en outre la valeur de l'objectif
  et le drapeau du solveur.

  SOLVE(...,'Solver',NOM) impose le solveur.

  Exemple :
     x = optimvar('x', 2, 'LowerBound', 0);
     prob = optimproblem('Objective', -x(1) - 2*x(2), ...
                         'ObjectiveSense', 'minimize');
     prob.Constraints.c1 = x(1) + x(2) <= 4;
     sol = solve(prob);
     sol.x

  Voir aussi OPTIMPROBLEM, OPTIMVAR, PROB2STRUCT, LINPROG, QUADPROG.
```

