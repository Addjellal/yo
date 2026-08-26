# Toolbox `compilateur`

```
% MATLAB Compiler — distribution d'un programme.
%
%   mcc        - Fabrique un lanceur autonome autour d'un script
%   deploytool - Décrit ce que contient le paquet produit
```

## `deploytool`

```
DEPLOYTOOL Décrit le paquet de distribution d'un script.
```

## `mcc`

```
MCC Fabrique un lanceur autonome pour un script.
  CHEMIN = MCC('script.m','programme') écrit un script shell qui appelle
  l'interpréteur MatLibre sur le script, avec le chemin des toolboxes
  déjà réglé. C'est l'équivalent libre du « MATLAB Runtime » : le
  programme produit a besoin de l'interpréteur, comme un programme
  compilé par mcc a besoin du runtime.
```

