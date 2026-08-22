# Toolbox `gestion-risques`

```
% Risk Management Toolbox — mesures de risque.
%
%   valueAtRisk       - VaR historique ou paramétrique
%   expectedShortfall - Perte moyenne au-delà de la VaR
%   drawdownSeries    - Série des pertes depuis le dernier sommet
%   riskContribution  - Contribution de chaque actif au risque
%   creditTransition  - Matrice de transition de notation
```

## `creditTransition`

```
CREDITTRANSITION Matrice de transition estimée sur des trajectoires.
  P = CREDITTRANSITION(N) où N est une matrice dont chaque ligne est la
  trajectoire de notation d'un émetteur.
```

## `drawdownSeries`

```
DRAWDOWNSERIES Perte relative depuis le dernier sommet, à chaque date.
```

## `expectedShortfall`

```
EXPECTEDSHORTFALL Perte moyenne conditionnelle au-delà de la VaR.
```

## `riskContribution`

```
RISKCONTRIBUTION Contribution marginale de chaque actif au risque total.
```

## `valueAtRisk`

```
VALUEATRISK Valeur en risque d'une série de rendements.
  V = VALUEATRISK(R,NIVEAU) rend la perte que l'on ne dépasse qu'avec la
  probabilité 1-NIVEAU (0.95 par défaut), par la méthode historique.
  'normal' utilise l'hypothèse gaussienne.
```

