# Toolbox `simscape`

```
% Simscape — réseaux physiques.
%
% Le solveur écrit les équations nodales du circuit (loi des nœuds), avec
% la méthode d'analyse nodale modifiée : les sources de tension et les
% inductances ajoutent une inconnue de courant.
%
%   circuit      - Crée un circuit vide
%   addResistor, addCapacitor, addInductor, addVoltageSource,
%   addCurrentSource - Ajout de composants entre deux nœuds
%   solveDC      - Point de fonctionnement continu
%   solveTransient - Réponse temporelle (Euler implicite)
```

## `addCapacitor`

```
ADDCAPACITOR Condensateur de C farads.
```

## `addComponent`

```
ADDCOMPONENT Ajoute un composant entre deux nœuds.
```

## `addCurrentSource`

```
ADDCURRENTSOURCE Source de courant idéale, de n1 vers n2.
```

## `addInductor`

```
ADDINDUCTOR Bobine de L henrys.
```

## `addResistor`

```
ADDRESISTOR Résistance de R ohms entre deux nœuds.
```

## `addVoltageSource`

```
ADDVOLTAGESOURCE Source de tension idéale de V volts (n1 au potentiel +).
```

## `circuit`

```
CIRCUIT Crée un circuit vide. Le nœud 0 est la masse.
```

## `solveDC`

```
SOLVEDC Point de fonctionnement continu par analyse nodale modifiée.
  [V,I] = SOLVEDC(C) rend le potentiel de chaque nœud (le nœud 0 étant
  la masse) et le courant de chaque source de tension.
  En régime continu, un condensateur est un circuit ouvert et une
  bobine un court-circuit.
```

## `solveTransient`

```
SOLVETRANSIENT Réponse temporelle par Euler implicite.
  [T,V] = SOLVETRANSIENT(C,TFINAL,PAS) intègre le circuit ; chaque
  condensateur est remplacé à chaque pas par une conductance C/h en
  parallèle avec une source de courant, et chaque bobine par une
  résistance L/h en série avec une source de tension (modèle compagnon
  de l'intégration implicite).

  SOURCETEMPS, facultative, est une poignée @(t) rendant un facteur
  multiplicatif appliqué aux sources de tension.
```

