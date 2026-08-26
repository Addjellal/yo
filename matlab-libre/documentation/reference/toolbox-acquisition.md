# Toolbox `acquisition`

```
% Data Acquisition Toolbox — acquisition simulée.
%
% Aucune carte n'est pilotée : les canaux produisent des signaux calculés,
% ce qui permet d'écrire et de tester une chaîne d'acquisition complète
% sans matériel.
%
%   daq          - Crée une session
%   addAnalogInput, addAnalogOutput - Ajout de voies
%   readData     - Lecture d'un bloc d'échantillons
%   writeData    - Écriture (mémorisée)
```

## `addAnalogInput`

```
ADDANALOGINPUT Ajoute une voie d'entrée.
  GENERATEUR est une poignée @(t) qui produit le signal mesuré.
```

## `addAnalogOutput`

```
ADDANALOGOUTPUT Ajoute une voie de sortie.
```

## `daq`

```
DAQ Crée une session d'acquisition simulée.
```

## `readData`

```
READDATA Lit un bloc d'échantillons sur toutes les voies d'entrée.
```

## `writeData`

```
WRITEDATA Écrit un bloc sur les voies de sortie (mémorisé).
```

