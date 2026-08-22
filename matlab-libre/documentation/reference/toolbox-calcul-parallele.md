# Toolbox `calcul-parallele`

```
% Parallel Computing Toolbox — exécution parallèle.
%
% MatLibre exécute « parfor » et « spmd » séquentiellement : le résultat
% est le même, seul le temps diffère. Les fonctions ci-dessous existent
% pour que le code écrit pour la toolbox tourne sans modification.
%
%   parpool, gcp, delete  - Pool de travailleurs (simulé)
%   parfeval, fetchOutputs- Exécution différée
%   distributed, gather   - Tableaux distribués (identité)
%   numlabs, labindex     - Identifiants de travailleur
%   pararrayfun           - arrayfun « parallèle »
```

## `distributed`

```
DISTRIBUTED Tableau distribué (identité sur une seule machine).
```

## `fetchOutputs`

```
FETCHOUTPUTS Résultats d'une tâche lancée par PARFEVAL.
```

## `gather`

```
GATHER Rapatrie un tableau distribué (identité ici).
```

## `gcp`

```
GCP Pool courant.
```

## `labindex`

```
LABINDEX Indice du travailleur courant.
```

## `numlabs`

```
NUMLABS Nombre de travailleurs.
```

## `pararrayfun`

```
PARARRAYFUN Équivalent parallèle d'ARRAYFUN (exécution séquentielle).
```

## `parfeval`

```
PARFEVAL Exécute une fonction et mémorise son résultat.
  Comme il n'y a qu'un fil, l'exécution est immédiate ; FETCHOUTPUTS
  rend le résultat déjà calculé.
```

## `parpool`

```
PARPOOL Ouvre un pool de travailleurs (simulé : un seul fil).
```

