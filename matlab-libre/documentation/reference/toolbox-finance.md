# Toolbox `finance`

```
% Financial Toolbox — finance quantitative.
%
%   pv, fv, npv, irr    - Valeurs actuelle et future, VAN, TRI
%   effrr, nomrr        - Taux effectif et nominal
%   blsprice, blsdelta, blsimpv - Modèle de Black-Scholes
%   movavg              - Moyennes mobiles
%   tick2ret, ret2tick  - Cours et rendements
%   maxdrawdown         - Perte maximale
%   portstats, portalloc- Rendement et risque d'un portefeuille
%   sharpe              - Ratio de Sharpe
```

## `blsdelta`

```
BLSDELTA Sensibilité du prix au cours du sous-jacent.
```

## `blsimpv`

```
BLSIMPV Volatilité implicite, par dichotomie sur BLSPRICE.
```

## `blsprice`

```
BLSPRICE Prix d'options européennes par la formule de Black-Scholes.
  [C,P] = BLSPRICE(S,K,R,T,SIGMA) rend les prix de l'achat et de la
  vente. Q est le taux de dividende continu (zéro par défaut).
```

## `effrr`

```
EFFRR Taux effectif annuel à partir du taux nominal.
```

## `fv`

```
FV Valeur future d'un placement à versements constants.
```

## `irr`

```
IRR Taux de rendement interne : le taux qui annule la valeur nette.
```

## `maxdrawdown`

```
MAXDRAWDOWN Perte maximale depuis un sommet.
```

## `movavg`

```
MOVAVG Moyennes mobiles courte et longue.
```

## `nomrr`

```
NOMRR Taux nominal à partir du taux effectif.
```

## `npv`

```
NPV Valeur actuelle nette : le premier flux est à la date zéro.
```

## `portalloc`

```
PORTALLOC Portefeuille de variance minimale pour un rendement cible.
  Résolution analytique par multiplicateurs de Lagrange.
```

## `portstats`

```
PORTSTATS Rendement et écart type d'un portefeuille.
```

## `pv`

```
PV Valeur actuelle d'une suite de flux, le premier à la période 1.
```

## `ret2tick`

```
RET2TICK Reconstruit une série de cours à partir des rendements.
```

## `sharpe`

```
SHARPE Ratio de Sharpe d'une série de rendements.
```

## `tick2ret`

```
TICK2RET Rendements à partir d'une série de cours.
  R = TICK2RET(P) rend les rendements simples ; 'continuous' donne les
  rendements logarithmiques.
```

