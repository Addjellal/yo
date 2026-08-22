# Toolbox `robuste`

```
% Robust Control Toolbox — analyse de robustesse.
%
%   hinfnorm     - Norme H-infini d'un modèle
%   h2norm       - Norme H2
%   sigmaValues  - Valeurs singulières en fréquence
%   stabilityMargin - Marges de module et de retard
%   uncertainGain   - Balayage d'un gain incertain
```

## `h2norm`

```
H2NORM Norme H2, par intégration du carré du module.
```

## `hinfnorm`

```
HINFNORM Norme H-infini, par balayage fréquentiel raffiné.
```

## `sigmaValues`

```
SIGMAVALUES Valeurs singulières en fonction de la pulsation.
```

## `stabilityMargin`

```
STABILITYMARGIN Marge de module et marge de retard d'une boucle ouverte.
  La marge de module est la distance minimale du lieu de Nyquist au
  point critique -1 ; la marge de retard s'en déduit par la marge de
  phase et la pulsation de coupure.
```

## `uncertainGain`

```
UNCERTAINGAIN Stabilité en boucle fermée pour un gain incertain.
```

