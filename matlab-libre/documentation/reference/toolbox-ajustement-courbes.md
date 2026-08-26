# Toolbox `ajustement-courbes`

```
% Curve Fitting Toolbox — ajustement de courbes et de surfaces.
%
%   fitCurve       - Ajustement par un modèle nommé
%   goodnessOfFit  - R2, RMSE, SSE
%   smoothSpline   - Lissage par spline pénalisée
%   fitSurface     - Ajustement polynomial d'une surface
```

## `fitCurve`

```
FITCURVE Ajustement par un modèle nommé.
  TYPE vaut 'poly', 'exp' (a e^{bx}), 'power' (a x^b), 'log' (a + b ln x)
  ou 'gauss' (a exp(-((x-b)/c)^2)).
```

## `fitSurface`

```
FITSURFACE Ajustement polynomial d'une surface z = f(x,y).
```

## `goodnessOfFit`

```
GOODNESSOFFIT Indicateurs de qualité d'un ajustement.
```

## `smoothSpline`

```
SMOOTHSPLINE Lissage par pénalisation de la dérivée seconde.
  YLISSE = SMOOTHSPLINE(X,Y,LAMBDA) minimise
     sum (y - f)^2 + lambda * sum (f'')^2
```

