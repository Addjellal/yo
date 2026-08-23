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
% Optimisation non linéaire
%   fmincon     - Minimisation sous contraintes
%   fminimax    - Minimise le pire des critères
%
% Moindres carrés
%   lsqlin      - Moindres carrés linéaires sous contraintes
%   lsqcurvefit - Ajustement de courbe
%   lsqnonlin   - Moindres carrés non linéaires (Levenberg-Marquardt)
%
% Réglages
%   optimoptions - Options d'un solveur, noms modernes et anciens
%
% Les fonctions natives fminsearch, fminbnd, fminunc, fsolve, fzero et
% lsqnonneg complètent l'ensemble.
```

## `bintprog`

```
BINTPROG Programmation linéaire en variables binaires, par énumération.
  X = BINTPROG(F,A,B) minimise f'*x sous A*x <= b, x dans {0,1}^n.
  L'énumération est exhaustive : à réserver aux petits problèmes.
```

## `fmincon`

```
FMINCON Minimisation sous contraintes, par pénalisation extérieure.
  X = FMINCON(F,X0,A,B) minimise F sous A*x <= b.
  Les contraintes non linéaires sont données par une fonction rendant
  [c, ceq] : c <= 0 et ceq == 0.
```

## `fminimax`

```
FMINIMAX Minimise le maximum d'un ensemble de fonctions.
  X = FMINIMAX(F,X0) où F(x) rend un vecteur : on minimise max(F(x)).
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
```

## `linprog`

```
LINPROG Programmation linéaire : minimise f'*x sous A*x <= b.
  [X,VAL] = LINPROG(F,A,B) résout le problème par une méthode de
  pénalisation intérieure : on minimise f'x - mu*sum(log(b - Ax)) pour
  une suite décroissante de mu, ce qui converge vers l'optimum du
  problème contraint.

  Les contraintes d'égalité sont traitées par pénalisation quadratique.
```

## `lsqcurvefit`

```
LSQCURVEFIT Ajustement non linéaire au sens des moindres carrés.
  P = LSQCURVEFIT(MODELE,P0,X,Y) minimise la somme des carrés des écarts
  entre MODELE(P,X) et Y.
```

## `lsqlin`

```
LSQLIN Moindres carrés linéaires avec contraintes de bornes.
  X = LSQLIN(C,D) minimise ||C*x - d||.
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
```

## `optimoptions`

```
OPTIMOPTIONS Options d'un solveur d'optimisation.
  OPTIONS = OPTIMOPTIONS('fmincon','Display','iter','MaxIterations',100)
  rend une structure d'options. Les noms modernes et les anciens sont
  acceptés : MaxIterations ou MaxIter, OptimalityTolerance ou TolFun,
  StepTolerance ou TolX.

  Voir aussi OPTIMSET.
```

## `quadprog`

```
QUADPROG Programmation quadratique : minimise 0.5*x'Hx + f'x.
  Les contraintes d'inégalité et les bornes sont traitées par
  pénalisation ; le minimum est cherché par Nelder-Mead à partir de la
  solution non contrainte.
```

