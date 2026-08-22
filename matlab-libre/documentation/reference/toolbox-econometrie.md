# Toolbox `econometrie`

```
% Econometrics Toolbox — séries temporelles et économétrie.
%
%   autocorr, parcorr - Autocorrélations simple et partielle
%   lagmatrix         - Matrice de retards
%   arfit             - Estimation d'un AR(p) par Yule-Walker
%   arsim             - Simulation d'un AR(p)
%   adftest           - Test de racine unitaire (Dickey-Fuller augmenté)
%   hurst             - Exposant de Hurst par R/S
%   ols               - Moindres carrés ordinaires avec diagnostics
```

## `adftest`

```
ADFTEST Test de Dickey-Fuller augmenté (modèle sans tendance).
  [H,T] = ADFTEST(Y) rend H=1 si la racine unitaire est rejetée au seuil
  de 5 %, en comparant la statistique aux valeurs critiques usuelles.
```

## `arfit`

```
ARFIT Estimation d'un modèle autorégressif par Yule-Walker.
  [PHI,SIGMA2,C] = ARFIT(Y,P) rend les coefficients, la variance du
  bruit et la constante.
```

## `arsim`

```
ARSIM Simulation d'un processus autorégressif.
```

## `autocorr`

```
AUTOCORR Fonction d'autocorrélation empirique.
```

## `hurst`

```
HURST Exposant de Hurst estimé par l'analyse R/S.
```

## `lagmatrix`

```
LAGMATRIX Matrice des versions retardées d'une série.
```

## `ols`

```
OLS Moindres carrés ordinaires, avec diagnostics.
```

## `parcorr`

```
PARCORR Autocorrélation partielle, par les équations de Yule-Walker.
```

