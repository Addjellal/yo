# Toolbox `calcul-parallele`

```
% Parallel Computing Toolbox — calcul distribué.
%
% Ce qui se parallélise est ce qui ne communique pas : chaque élément
% traité seul, sans dépendre de ce que les autres deviennent.
%
% Application élément par élément
%   pararrayfun  - Équivalent parallèle d'ARRAYFUN
%   parcellfun   - Équivalent parallèle de CELLFUN
%
% Données
%   distributed  - Marque un tableau comme distribué
%   gather       - Le rapatrie : l'appel qui coûte, sur un vrai pool
```

## `distributed`

```
DISTRIBUTED Tableau distribué.
  Y = DISTRIBUTED(X) marque un tableau comme distribué sur le pool. Sur
  une seule machine, c'est l'identité.

  Ce n'est pas décoratif pour autant : DISTRIBUTED et GATHER marquent
  dans le code les endroits où les données passeraient d'une machine à
  l'autre. Un programme écrit avec eux tourne sans changement sur un
  vrai pool, et sa lecture dit où sont les communications — qui coûtent
  toujours plus cher que le calcul.

  Exemple :
     d = distributed(magic(4));
     isequal(gather(d), magic(4))    % true

  Voir aussi GATHER, PARARRAYFUN, PARCELLFUN.
```

## `gather`

```
GATHER Rapatrie un tableau distribué.
  Y = GATHER(X) ramène un tableau distribué dans l'espace de travail
  local. Sur une seule machine, c'est l'identité.

  GATHER annule exactement DISTRIBUTED, sur un tableau vide comme sur du
  texte. C'est le contrat, et il tient quel que soit le contenu.

  Sur un vrai pool, c'est l'appel qui coûte : il rassemble sur une seule
  machine ce qui était réparti. Le placer dans une boucle est la façon
  la plus sûre de perdre tout le bénéfice du parallélisme.

  Exemple :
     gather(distributed([]))         % []
     gather(distributed('texte'))    % 'texte'

  Voir aussi DISTRIBUTED, PARARRAYFUN.
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

