# Toolbox `flou`

```
% Fuzzy Logic Toolbox — logique floue.
%
%   trimf, trapmf, gaussmf, sigmf, gbellmf - Fonctions d'appartenance
%   newfis, addvar, addmf, addrule         - Construction d'un système
%   evalfis                                - Inférence de Mamdani
%   defuzz                                 - Défuzzification
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

## `evalfis`

```
EVALFIS Inférence de Mamdani avec défuzzification par centre de gravité.
  Y = EVALFIS(X,FIS) évalue le système pour le vecteur d'entrées X.
```

## `evalmf`

```
EVALMF Évalue une fonction d'appartenance par son nom.
```

## `gaussmf`

```
GAUSSMF Fonction d'appartenance gaussienne de paramètres [sigma centre].
```

## `gbellmf`

```
GBELLMF Cloche généralisée de paramètres [a b c].
```

## `newfis`

```
NEWFIS Crée un système d'inférence floue de Mamdani.
```

## `sigmf`

```
SIGMF Fonction d'appartenance sigmoïde de paramètres [pente centre].
```

## `trapmf`

```
TRAPMF Fonction d'appartenance trapézoïdale de paramètres [a b c d].
```

## `trimf`

```
TRIMF Fonction d'appartenance triangulaire de paramètres [a b c].
```

