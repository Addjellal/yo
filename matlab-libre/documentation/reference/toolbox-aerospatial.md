# Toolbox `aerospatial`

```
% Aerospace Toolbox — atmosphère, repères et grandeurs de vol.
%
%   atmosisa    - Atmosphère type internationale
%   angle2dcm   - Angles d'Euler vers matrice de cosinus directeurs
%   dcm2angle   - Réciproque
%   machnumber  - Nombre de Mach
%   dpressure   - Pression dynamique
%   geodetic2ecef - Coordonnées géodésiques vers repère terrestre
```

## `angle2dcm`

```
ANGLE2DCM Angles d'Euler (radians) vers matrice de cosinus directeurs.
  L'ordre par défaut est ZYX, comme dans la documentation.
```

## `atmosisa`

```
ATMOSISA Atmosphère type internationale (troposphère et stratosphère).
  [T,A,P,RHO] = ATMOSISA(H) rend la température (K), la vitesse du son
  (m/s), la pression (Pa) et la masse volumique (kg/m^3).
```

## `dcm2angle`

```
DCM2ANGLE Matrice de cosinus directeurs vers angles d'Euler ZYX.
```

## `dpressure`

```
DPRESSURE Pression dynamique 0.5 rho V^2.
```

## `geodetic2ecef`

```
GEODETIC2ECEF Coordonnées géodésiques (degrés) vers repère terrestre WGS84.
```

## `machnumber`

```
MACHNUMBER Nombre de Mach.
```

