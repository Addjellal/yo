# Toolbox `simscape`

```
% Simscape — réseaux physiques.
%
% Le solveur écrit les équations nodales du circuit — la loi des nœuds —
% par la méthode d'analyse nodale modifiée : les sources de tension et les
% bobines ajoutent chacune une inconnue de courant et une équation, ce que
% l'analyse nodale seule ne saurait traiter.
%
% Description
%   circuit            - Crée un circuit vide, le nœud 0 étant la masse
%   addComponent       - Forme générale dont dérivent les suivantes
%   addResistor        - Résistance
%   addCapacitor       - Condensateur
%   addInductor        - Bobine
%   addVoltageSource   - Source de tension idéale
%   addCurrentSource   - Source de courant idéale
%
% Résolution
%   solveDC            - Point de fonctionnement continu
%   solveTransient     - Réponse temporelle, par Euler implicite
```

## `addCapacitor`

```
ADDCAPACITOR Condensateur de C farads.
  C = ADDCAPACITOR(C,N1,N2,VALEUR) ajoute un condensateur.

  En régime continu établi, un condensateur est un circuit ouvert :
  SOLVEDC le traite comme tel, et la tension à ses bornes vaut celle que
  le reste du circuit y impose. C'est en transitoire qu'il fait quelque
  chose, et SOLVETRANSIENT le remplace alors à chaque pas par une
  conductance en parallèle avec une source de courant.

  Exemple :
     c = addCapacitor(c, 2, 0, 1e-6);
     [t, v] = solveTransient(c, 0.01, 1e-5);

  Voir aussi ADDINDUCTOR, ADDRESISTOR, SOLVETRANSIENT.
```

## `addComponent`

```
ADDCOMPONENT Ajoute un composant entre deux nœuds.
  C = ADDCOMPONENT(C,TYPE,N1,N2,VALEUR) est la forme générale dont
  dérivent ADDRESISTOR, ADDCAPACITOR, ADDINDUCTOR, ADDVOLTAGESOURCE et
  ADDCURRENTSOURCE. TYPE vaut 'r', 'c', 'l', 'v' ou 'i'.

  Le circuit retient au passage le plus grand numéro de nœud employé :
  c'est ainsi qu'il connaît sa taille, sans qu'on ait à la déclarer.

  Exemple :
     c = addComponent(c, 'r', 1, 2, 1000);   % equivaut a addResistor

  Voir aussi ADDRESISTOR, ADDCAPACITOR, ADDINDUCTOR, CIRCUIT.
```

## `addCurrentSource`

```
ADDCURRENTSOURCE Source de courant idéale, de n1 vers n2.
  C = ADDCURRENTSOURCE(C,N1,N2,I) fait circuler I ampères de N1 vers N2
  à l'intérieur de la source, donc de N2 vers N1 dans le circuit
  extérieur. Elle est idéale : sa résistance interne est infinie, et la
  tension à ses bornes est celle que le circuit impose.

  Une source de courant n'ajoute pas d'inconnue : elle entre directement
  dans la loi des nœuds, contrairement à une source de tension.

  Exemple :
     c = addCurrentSource(c, 0, 1, 0.005);
     c = addResistor(c, 1, 0, 1000);
     solveDC(c)                      % 5 V : R I

  Voir aussi ADDVOLTAGESOURCE, SOLVEDC.
```

## `addInductor`

```
ADDINDUCTOR Bobine de L henrys.
  C = ADDINDUCTOR(C,N1,N2,VALEUR) ajoute une bobine.

  En régime continu établi, une bobine est un court-circuit : SOLVEDC
  la traite comme tel, et le courant qui la traverse est celui que le
  reste du circuit impose. C'est le dual du condensateur, et les deux
  ensemble donnent le second ordre — donc les oscillations.

  Exemple :
     c = addInductor(c, 2, 3, 1e-3);

  Voir aussi ADDCAPACITOR, ADDRESISTOR, SOLVETRANSIENT.
```

## `addResistor`

```
ADDRESISTOR Résistance de R ohms entre deux nœuds.
  C = ADDRESISTOR(C,N1,N2,R) ajoute une résistance. Elle n'a pas de
  sens : les deux nœuds jouent le même rôle.

  En série les résistances s'ajoutent, en parallèle ce sont les
  conductances : le solveur retrouve les deux règles sans qu'on ait à
  les lui dire.

  Exemple :
     c = addResistor(c, 1, 2, 1000);

  Voir aussi ADDCAPACITOR, ADDINDUCTOR, SOLVEDC.
```

## `addVoltageSource`

```
ADDVOLTAGESOURCE Source de tension idéale de V volts.
  C = ADDVOLTAGESOURCE(C,N1,N2,V) impose V volts entre les deux nœuds,
  N1 au potentiel le plus haut. La source est idéale : sa résistance
  interne est nulle, et elle débite ce qu'il faut.

  Une source de tension ajoute une inconnue au système — son courant —
  et une équation : c'est ce que « modifiée » veut dire dans « analyse
  nodale modifiée ». SOLVEDC rend ce courant en second résultat.

  Le signe du courant rendu est celui qui entre par la borne moins :
  il est donc négatif quand la source débite.

  Exemple :
     c = addVoltageSource(c, 1, 0, 10);
     [v, i] = solveDC(c);
     abs(i(1))                       % le courant debite

  Voir aussi ADDCURRENTSOURCE, SOLVEDC, SOLVETRANSIENT.
```

## `circuit`

```
CIRCUIT Crée un circuit vide.
  C = CIRCUIT(NOM) rend un circuit sans composant. Le nœud 0 est la
  masse, et les autres se numérotent librement : le circuit compte comme
  nœuds tous ceux qu'un composant nomme.

  Décrire un circuit, non les équations qui le régissent : c'est le
  propos. On pose des composants entre des nœuds, et SOLVEDC ou
  SOLVETRANSIENT écrivent et résolvent le système.

  Exemple :
     c = circuit('diviseur');
     c = addVoltageSource(c, 1, 0, 10);
     c = addResistor(c, 1, 2, 1000);
     c = addResistor(c, 2, 0, 2000);
     v = solveDC(c)                  % v(2) = 6,667 V

  Voir aussi ADDRESISTOR, ADDCAPACITOR, ADDINDUCTOR, ADDVOLTAGESOURCE,
  ADDCURRENTSOURCE, SOLVEDC, SOLVETRANSIENT.
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

