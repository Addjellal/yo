# Toolbox `flou`

```
% Fuzzy Logic Toolbox — logique floue.
%
%   trimf, trapmf, gaussmf, sigmf, gbellmf - Fonctions d'appartenance
%   newfis, addvar, addmf, addrule         - Construction d'un système
%   evalfis                                - Inférence de Mamdani
%   defuzz                                 - Défuzzification
%
% Fonctions d'appartenance supplémentaires
%   zmf, smf, pimf   - Courbes en Z, en S et en Pi
%   dsigmf, psigmf   - Différence et produit de sigmoïdes
%   gauss2mf         - Deux demi-gaussiennes et un plateau
%
% Inspection
%   showrule    - Écrit les règles en clair
%   gensurf     - Surface de réponse
```

## `addmf`

```
ADDMF Ajoute une fonction d'appartenance à une variable.
```

## `addrule`

```
ADDRULE Ajoute des règles.
  Chaque ligne vaut [mfEntree1 ... mfEntreeN mfSortie poids operateur],
  où l'opérateur vaut 1 pour « et », 2 pour « ou », comme dans la
  documentation MathWorks.
```

## `addvar`

```
ADDVAR Ajoute une variable d'entrée ou de sortie.
  FIS = ADDVAR(FIS,'input'|'output',NOM,[MIN MAX])
```

## `defuzz`

```
DEFUZZ Défuzzification d'un ensemble flou.
  Y = DEFUZZ(X,MF,'centroid'|'bisector'|'mom'|'som'|'lom')
```

## `dsigmf`

```
DSIGMF Différence de deux sigmoïdes.
  Y = DSIGMF(X,[A1 C1 A2 C2]) = sigmf(X,[A1 C1]) - sigmf(X,[A2 C2]).
```

## `evalfis`

```
EVALFIS Inférence de Mamdani avec défuzzification par centre de gravité.
  Y = EVALFIS(X,FIS) évalue le système pour le vecteur d'entrées X.
```

## `evalmf`

```
EVALMF Évalue une fonction d'appartenance par son nom.
```

## `gauss2mf`

```
GAUSS2MF Deux demi-gaussiennes raccordées par un plateau.
  Y = GAUSS2MF(X,[S1 C1 S2 C2]) : montée gaussienne jusqu'à C1, plateau
  à 1 entre C1 et C2, descente gaussienne après C2.
```

## `gaussmf`

```
GAUSSMF Fonction d'appartenance gaussienne de paramètres [sigma centre].
```

## `gbellmf`

```
GBELLMF Cloche généralisée de paramètres [a b c].
```

## `gensurf`

```
GENSURF Surface de réponse d'un système flou.
  [X,Y,Z] = GENSURF(FIS) évalue la sortie sur une grille des deux
  premières entrées. Sans sortie demandée, la surface est tracée.

  Exemple :
     [x, y, z] = gensurf(fis);
```

## `newfis`

```
NEWFIS Crée un système d'inférence floue de Mamdani.
```

## `pimf`

```
PIMF Fonction d'appartenance en Pi : montée en S puis descente en Z.
  Y = PIMF(X,[A B C D]) monte de A à B, vaut 1 de B à C, descend de C
  à D.

  Exemple :  pimf(5, [1 4 6 9])   % 1
```

## `psigmf`

```
PSIGMF Produit de deux sigmoïdes.
  Y = PSIGMF(X,[A1 C1 A2 C2]) = sigmf(X,[A1 C1]) .* sigmf(X,[A2 C2]).
```

## `showrule`

```
SHOWRULE Affiche les règles d'un système flou, en clair.
  SHOWRULE(FIS) écrit toutes les règles ; TEXTE = SHOWRULE(FIS) les
  rend en cellule de chaînes.

  Exemple :
     fis = newfis('essai');
     showrule(fis)
```

## `sigmf`

```
SIGMF Fonction d'appartenance sigmoïde de paramètres [pente centre].
```

## `smf`

```
SMF Fonction d'appartenance en S : croît de 0 à 1.
  C'est le complément de ZMF sur le même intervalle.

  Exemple :  smf(10, [2 8])   % 1
```

## `trapmf`

```
TRAPMF Fonction d'appartenance trapézoïdale de paramètres [a b c d].
```

## `trimf`

```
TRIMF Fonction d'appartenance triangulaire de paramètres [a b c].
```

## `zmf`

```
ZMF Fonction d'appartenance en Z : décroît de 1 à 0.
  Y = ZMF(X,[A B]) vaut 1 avant A, 0 après B, avec deux arcs de
  parabole raccordés au milieu — la courbe est donc dérivable.

  Exemple :  zmf(0, [2 8])   % 1
```

