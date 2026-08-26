# Toolbox `robotique`

```
% Robotics System Toolbox — cinématique et transformations.
%
%   rotx, roty, rotz    - Rotations élémentaires
%   eul2rotm, rotm2eul  - Angles d'Euler ZYX
%   eul2quat, quat2rotm, rotm2quat - Quaternions
%   quatmultiply, quatconj, quatnormalize
%   trvec2tform, tform2trvec, rotm2tform, tform2rotm
%   dhTransform         - Matrice de Denavit-Hartenberg
%   fkine2R, ikine2R    - Cinématique d'un bras plan à deux segments
%   jacobian2R          - Jacobienne du même bras
```

## `dhTransform`

```
DHTRANSFORM Matrice de passage de Denavit-Hartenberg.
  T = DHTRANSFORM(A,ALPHA,D,THETA) avec la convention standard :
  rotation THETA autour de z, translation D selon z, translation A selon
  x, rotation ALPHA autour de x.
```

## `eul2quat`

```
EUL2QUAT Angles d'Euler ZYX vers quaternion.
```

## `eul2rotm`

```
EUL2ROTM Angles d'Euler ZYX (radians) vers matrice de rotation.
```

## `fkine2R`

```
FKINE2R Cinématique directe d'un bras plan à deux segments.
  [X,Y] = FKINE2R([Q1 Q2],L1,L2) rend la position de l'effecteur.
```

## `ikine2R`

```
IKINE2R Cinématique inverse d'un bras plan à deux segments.
  Q = IKINE2R(X,Y,L1,L2) rend les deux angles articulaires.
```

## `jacobian2R`

```
JACOBIAN2R Jacobienne d'un bras plan à deux segments.
```

## `quat2rotm`

```
QUAT2ROTM Quaternion [w x y z] vers matrice de rotation.
```

## `quatconj`

```
QUATCONJ Conjugué d'un quaternion.
```

## `quatmultiply`

```
QUATMULTIPLY Produit de deux quaternions [w x y z].
```

## `quatnormalize`

```
QUATNORMALIZE Quaternion unitaire.
```

## `rotm2eul`

```
ROTM2EUL Matrice de rotation vers angles d'Euler ZYX (radians).
```

## `rotm2quat`

```
ROTM2QUAT Matrice de rotation vers quaternion [w x y z].
```

## `rotm2tform`

```
ROTM2TFORM Rotation vers matrice homogène.
```

## `rotx`

```
ROTX Rotation autour de l'axe x, angle en degrés.
```

## `roty`

```
ROTY Rotation autour de l'axe y, angle en degrés.
```

## `rotz`

```
ROTZ Rotation autour de l'axe z, angle en degrés.
```

## `tform2rotm`

```
TFORM2ROTM Rotation contenue dans une matrice homogène.
```

## `tform2trvec`

```
TFORM2TRVEC Translation contenue dans une matrice homogène.
```

## `trvec2tform`

```
TRVEC2TFORM Vecteur de translation vers matrice homogène 4x4.
```

