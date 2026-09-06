# Toolbox `calcul-parallele`

```
% Parallel Computing Toolbox — exécution parallèle.
%
% « parfor » et « spmd » s'exécutent réellement en parallèle : chaque
% travailleur est un interpréteur complet, avec son propre espace de
% travail, et rien n'est partagé. Le résultat est celui de la boucle
% séquentielle ; le temps, lui, se divise par le nombre de cœurs.
%
% Pool
%   parpool     - Ouvre un pool de N travailleurs (natif)
%   gcp         - Pool courant, créé au besoin (natif)
%   delete      - Ferme le pool passé en argument (natif)
%
% Travaux asynchrones
%   parfeval      - Lance une fonction sur un travailleur (natif)
%   parfevalOnAll - La lance sur tous les travailleurs (natif)
%   fetchOutputs  - Récupère le résultat (natif)
%   wait, cancel  - Attend, annule (natif)
%
% Dans un bloc spmd
%   labindex, numlabs - Numéro du travailleur et taille du pool
%
% Tableaux
%   distributed, gather - Tableaux distribués (identité sur une machine)
%   pararrayfun         - arrayfun réparti sur le pool
%   parcellfun          - cellfun réparti sur le pool
```

## `distributed`

```
DISTRIBUTED Tableau distribué (identité sur une seule machine).
```

## `gather`

```
GATHER Rapatrie un tableau distribué (identité ici).
```

## `matlibre_par_appliquer`

```
MATLIBRE_PAR_APPLIQUER Corps commun de PARARRAYFUN et PARCELLFUN.
  SORTIES = MATLIBRE_PAR_APPLIQUER(F,ENTREES,OPTIONS,EXTRAIRE,N) applique
  F à chaque élément, en parallèle, et rend N sorties dans une cellule.
  EXTRAIRE est la poignée qui prend le i-ème élément d'une entrée : elle
  seule diffère entre un tableau et une cellule.

  OPTIONS est une structure à deux champs : uniforme, et gestionnaire —
  la poignée d'ErrorHandler, vide s'il n'y en a pas.

  Les tâches partent toutes avant qu'on en attende aucune : c'est ce qui
  les rend simultanées. Les résultats se relisent ensuite dans l'ordre
  des indices, si bien que le résultat ne dépend pas de l'ordre où les
  travailleurs finissent.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_par_options`

```
MATLIBRE_PAR_OPTIONS Sépare les entrées des options nommées.
  [ENTREES,OPTIONS] = MATLIBRE_PAR_OPTIONS(ARGUMENTS,RECONNUES) retire
  des arguments les paires nom-valeur dont le nom figure dans RECONNUES,
  et rend une structure à deux champs : uniforme et gestionnaire.

  Une option ne se reconnaît qu'en fin de liste et suivie d'une valeur :
  une cellule de chaînes passée comme donnée ne doit pas être prise pour
  un nom d'option.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `pararrayfun`

```
PARARRAYFUN Équivalent parallèle d'ARRAYFUN.
  V = PARARRAYFUN(F,A) applique F à chaque élément de A, chacun sur un
  travailleur du pool, et rend les résultats dans l'ordre des indices.
  PARARRAYFUN(F,A,B,...) apparie les tableaux élément par élément.

  Options, comme ARRAYFUN :
     'UniformOutput'  false pour rendre une cellule
     'ErrorHandler'   une poignée appelée quand F échoue

  [X,Y,...] = PARARRAYFUN(...) rend autant de sorties que F en donne.

  Le résultat est exactement celui d'ARRAYFUN : c'est la garantie qui
  fait tout l'intérêt de la fonction, et elle interdit à F de dépendre
  de l'ordre d'exécution ou d'un état partagé. Une fonction qui
  accumule dans une variable extérieure, ou qui tire au sort, ne se
  parallélise pas ainsi.

  Exemple :
     pararrayfun(@(x) x^2, 1:4)                    % [1 4 9 16]
     pararrayfun(@(n) ones(1,n), 1:3, 'UniformOutput', false)

  Voir aussi PARCELLFUN, ARRAYFUN, PARFEVAL, DISTRIBUTED.
```

## `parcellfun`

```
PARCELLFUN Équivalent parallèle de CELLFUN.
  V = PARCELLFUN(F,C) applique F au contenu de chaque case de C, chacune
  sur un travailleur du pool.
  PARCELLFUN(F,C,D,...) apparie les cellules case par case.

  Options, comme CELLFUN :
     'UniformOutput'  false pour rendre une cellule
     'ErrorHandler'   une poignée appelée quand F échoue

  [X,Y,...] = PARCELLFUN(...) rend autant de sorties que F en donne.

  Exemple :
     parcellfun(@numel, {'a', 'bb', 'ccc'})        % [1 2 3]
     parcellfun(@upper, {'a','b'}, 'UniformOutput', false)

  Voir aussi PARARRAYFUN, CELLFUN, PARFEVAL.
```

