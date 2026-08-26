# Toolbox `edp`

```
% Partial Differential Equation Toolbox — équations aux dérivées partielles.
%
%   poisson2D  - Équation de Poisson sur un rectangle (différences finies)
%   heat1D     - Équation de la chaleur en 1-D (Crank-Nicolson)
%   wave1D     - Équation des ondes en 1-D (différences centrées)
%   laplace2D  - Équation de Laplace avec conditions de Dirichlet
%   fem1D      - Éléments finis P1 en 1-D
```

## `fem1D`

```
FEM1D Éléments finis P1 pour -u'' = f, u(0) = u(L) = 0.
```

## `heat1D`

```
HEAT1D Équation de la chaleur, schéma de Crank-Nicolson.
  [U,X,T] = HEAT1D(U0,ALPHA,L,TFINAL,NX,NT) avec U0 une poignée @(x)
  et des bords maintenus à zéro.
```

## `laplace2D`

```
LAPLACE2D Équation de Laplace avec conditions de Dirichlet constantes.
```

## `poisson2D`

```
POISSON2D Résout -laplacien(u) = f sur un rectangle, u nul au bord.
  [U,X,Y] = POISSON2D(F,NX,NY) où F est une poignée @(x,y).
```

## `wave1D`

```
WAVE1D Équation des ondes en 1-D, différences centrées.
```

