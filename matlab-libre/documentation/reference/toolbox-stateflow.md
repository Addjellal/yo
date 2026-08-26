# Toolbox `stateflow`

```
% Stateflow — machines à états finis.
%
%   sfchart      - Crée une machine
%   sfstate      - Ajoute un état, avec ses actions
%   sftransition - Ajoute une transition gardée
%   sfrun        - Exécute la machine sur une suite d'entrées
```

## `sfchart`

```
SFCHART Crée une machine à états vide.
```

## `sfrun`

```
SFRUN Exécute la machine sur une suite d'entrées.
  [HISTORIQUE,CONTEXTE] = SFRUN(MACHINE,ENTREES) rend la suite des états
  visités, un par pas, et le contexte final.
```

## `sfstate`

```
SFSTATE Ajoute un état.
  MACHINE = SFSTATE(MACHINE,NOM,ENTREE,PENDANT,SORTIE) où les trois
  actions sont des poignées de fonction prenant et rendant le contexte
  (une structure de données de la machine). Passer [] pour aucune action.
```

## `sftransition`

```
SFTRANSITION Ajoute une transition gardée.
  GARDE est une poignée @(contexte,entree) qui rend vrai ou faux.
  ACTION, facultative, est une poignée @(contexte) qui rend le contexte.
```

