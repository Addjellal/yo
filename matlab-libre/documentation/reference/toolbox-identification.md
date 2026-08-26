# Toolbox `identification`

```
% System Identification Toolbox — identification de modèles.
%
%   iddata     - Jeu de données entrée/sortie
%   arx        - Estimation d'un modèle ARX par moindres carrés
%   armax      - Estimation ARMAX (pseudo-linéaire)
%   compareFit - Qualité d'ajustement en pour cent
%   impulseest - Réponse impulsionnelle estimée
%   predictArx - Prédiction à un pas
```

## `armax`

```
ARMAX Estimation ARMAX par la méthode pseudo-linéaire.
  MODELE = ARMAX(DONNEES,[na nb nc nk]) alterne estimation des
  paramètres et reconstruction du bruit.
```

## `arx`

```
ARX Estimation d'un modèle ARX par moindres carrés.
  MODELE = ARX(DONNEES,[na nb nk]) ajuste
     y(t) + a1 y(t-1) + ... = b1 u(t-nk) + ...
```

## `compareFit`

```
COMPAREFIT Qualité d'ajustement, en pour cent (critère de MathWorks).
  FIT = 100 (1 - ||y - yhat|| / ||y - moyenne(y)||)
```

## `iddata`

```
IDDATA Jeu de données entrée/sortie.
```

## `impulseest`

```
IMPULSEEST Réponse impulsionnelle estimée par moindres carrés.
```

## `predictArx`

```
PREDICTARX Prédiction à un pas d'un modèle ARX.
```

