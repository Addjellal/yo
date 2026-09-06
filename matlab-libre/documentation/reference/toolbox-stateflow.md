# Toolbox `stateflow`

```
% Stateflow — machines à états finis.
%
% Construction
%   sfchart      - Crée une machine ; le premier état est l'initial
%   sfstate      - Ajoute un état et ses actions d'entrée, de séjour et
%                  de sortie
%   sftransition - Ajoute une transition gardée, avec sa priorité
%
% Exécution
%   sfrun        - Exécute sur une suite d'entrées ; rend l'historique
%                  des états et le contexte final
```

## `sfchart`

```
SFCHART Crée une machine à états vide.
  MACHINE = SFCHART(NOM) rend une machine sans état ni transition. Le
  premier état ajouté devient l'état initial.

  Un système à modes ne se décrit pas par une équation mais par un
  automate : des états, et des transitions gardées qui disent quand on
  passe de l'un à l'autre. Toute la logique tient dans les gardes.

  Ce qui distingue un automate d'une fonction : la même entrée n'a pas
  le même effet selon l'état. C'est cette mémoire qui permet de compter,
  de reconnaître une suite, ou de tenir un mode.

  Exemple :
     m = sfchart('tourniquet');
     m = sfstate(m, 'verrouille');
     m = sfstate(m, 'ouvert');
     m = sftransition(m, 'verrouille', 'ouvert', @(c,e) strcmp(e,'piece'));
     m = sftransition(m, 'ouvert', 'verrouille', @(c,e) strcmp(e,'pousse'));
     sfrun(m, {'pousse', 'piece', 'pousse'})

  Voir aussi SFSTATE, SFTRANSITION, SFRUN.
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
  MACHINE = SFSTATE(MACHINE,NOM,ENTREE,PENDANT,SORTIE) ajoute un état et
  ses trois actions, chacune une poignée qui prend le contexte et le
  rend modifié. Passer [] pour aucune action.

  Les trois moments ne sont pas une question de style :
     ENTREE   s'exécute une fois, quand on entre dans l'état
     PENDANT  s'exécute à chaque pas passé dans l'état
     SORTIE   s'exécute une fois, quand on en sort

  Compter les fronts d'un signal demande une action d'entrée ; mesurer
  la durée d'un mode demande une action de séjour. Les confondre donne
  des comptes faux.

  Le premier état ajouté est l'état initial de la machine.

  Le contexte est une structure quelconque que la machine porte d'un pas
  à l'autre : c'est ce qui lui permet de compter, donc de dépasser la
  seule mémoire d'état.

  Exemple :
     m = sfstate(m, 'compte', @(c) setfield(c, 'total', c.total + 1));
     [~, contexte] = sfrun(m, [1 0 1 0 1], struct('total', 0));

  Voir aussi SFCHART, SFTRANSITION, SFRUN.
```

## `sftransition`

```
SFTRANSITION Ajoute une transition gardée.
  MACHINE = SFTRANSITION(MACHINE,DEPUIS,VERS,GARDE,ACTION) ajoute une
  transition entre deux états. GARDE est une poignée @(contexte,entree)
  qui rend vrai ou faux ; ACTION, facultative, une poignée @(contexte)
  qui rend le contexte modifié au passage.

  Quand plusieurs transitions partent du même état, la première déclarée
  dont la garde est vraie l'emporte. C'est une règle de priorité, et il
  faut la connaître : elle décide du comportement quand deux conditions
  se recouvrent.

  Si aucune garde n'est vraie, la machine reste où elle est. Ne rien
  faire est un comportement, non une erreur.

  Exemple :
     m = sftransition(m, 'depart', 'petit', @(c,e) e < 10);
     m = sftransition(m, 'depart', 'grand', @(c,e) e < 100);
     sfrun(m, 5)                     % 'petit' : la premiere gagne

  Voir aussi SFCHART, SFSTATE, SFRUN.
```

