# Toolbox `mpc`

```
% Model Predictive Control Toolbox — commande prédictive.
%
%   mpcSetup   - Prépare un contrôleur prédictif linéaire
%   mpcmove    - Calcule la commande à appliquer
%   mpcsim     - Simulation en boucle fermée
```

## `mpcSetup`

```
MPCSETUP Prépare un contrôleur prédictif à horizon fuyant.
  Le problème résolu à chaque pas est
     min sum ||y(k) - r||^2 Q + ||du(k)||^2 R
  sur l'horizon de prédiction, la commande étant maintenue constante
  au-delà de l'horizon de commande.
```

## `mpcmove`

```
MPCMOVE Commande optimale à appliquer à l'instant courant.
```

## `mpcsim`

```
MPCSIM Simulation en boucle fermée du contrôleur prédictif.
```

