# Toolbox `optimisation`

```
% Optimization Toolbox — optimisation sous contraintes.
%
% Les solveurs sans contrainte (fzero, fminsearch, fminunc, fsolve,
% integral, ode45) sont natifs. Ce dossier ajoute la programmation
% linéaire et quadratique, et les moindres carrés.
%
%   linprog     - Programmation linéaire (points intérieurs)
%   quadprog    - Programmation quadratique (gradient projeté)
%   fmincon     - Minimisation sous contraintes (pénalisation)
%   lsqcurvefit - Ajustement de courbe non linéaire
%   lsqlin      - Moindres carrés linéaires sous contraintes de bornes
%   fminimax    - Minimisation du pire cas
%   bintprog    - Programmation en nombres binaires (énumération)
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

## `quadprog`

```
QUADPROG Programmation quadratique : minimise 0.5*x'Hx + f'x.
  Les contraintes d'inégalité et les bornes sont traitées par
  pénalisation ; le minimum est cherché par Nelder-Mead à partir de la
  solution non contrainte.
```

