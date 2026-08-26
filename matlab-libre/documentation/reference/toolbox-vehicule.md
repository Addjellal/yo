# Toolbox `vehicule`

```
% Vehicle Dynamics / Powertrain — dynamique du véhicule.
%
%   bicycleModel  - Modèle bicyclette cinématique
%   tireForce     - Force longitudinale et latérale (modèle de Pacejka simplifié)
%   longitudinal  - Équation longitudinale avec résistances
%   gearRatioSpeed- Vitesse en fonction du régime et du rapport
```

## `bicycleModel`

```
BICYCLEMODEL Un pas du modèle bicyclette cinématique.
  ETAT vaut [x y theta].
```

## `gearRatioSpeed`

```
GEARRATIOSPEED Vitesse du véhicule pour un régime moteur donné.
  REGIME en tours par minute, VITESSE en mètres par seconde.
```

## `longitudinal`

```
LONGITUDINAL Accélération longitudinale avec résistances.
```

## `tireForce`

```
TIREFORCE Force du pneu par la formule magique de Pacejka.
```

