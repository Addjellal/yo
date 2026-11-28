# Toolbox `stateflow`

```
% Stateflow — machines à états finis.
%
% Construction
%   sfchart      - Crée une machine ; le premier état est l'initial
%   sfstate      - Ajoute un état et ses actions d'entrée, de séjour et
%                  de sortie
%   sftransition - Ajoute une transition gardée, avec sa priorité
%   sfdecomposition - Rend les sous-états d'un état parallèles
%   sfhistory    - Donne un historique à un état
%   sfjunction   - Ajoute une jonction de connexion
%   sffunction   - Ajoute une fonction, appelee par les textes
%   sftruthtable - Ajoute une table de verite
%   sfdefault    - Choisit le sous-état où l'on entre par défaut
%   sfevent      - Déclare un événement d'entrée — il arrive par le port
%                  de déclenchement d'un bloc Chart — ou de sortie, émis
%                  par send(nom)
%
% Logique temporelle, dans les gardes et les actions
%   sfafter      - Après N réveils, ou N secondes, dans l'état
%   sfbefore     - Avant N réveils, ou N secondes
%   sfat         - Au N-ième réveil
%   sfevery      - Tous les N réveils
%
% Exécution
%   sfrun        - Exécute sur une suite d'entrées ; rend l'historique
%                  des états et le contexte final
%   sfstep       - Fait un pas, avec la règle de Stateflow : une
%                  transition valide, sinon l'action de séjour
```

## `matlibre_sf_etiquette`

_Pas de bloc d'aide._

## `matlibre_sf_evaluer`

_Pas de bloc d'aide._

## `matlibre_sf_temporel`

```
MATLIBRE_SF_TEMPOREL La logique temporelle d'un texte de Stateflow.
  VRAI = MATLIBRE_SF_TEMPOREL(CONTEXTE,OPERATEUR,N,UNITE) rend
  after(N, UNITE), before, at ou every, lus sur le contexte : c'est ce
  qu'un texte « after(3, tick) » devient avant d'être évalué.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_sf_temporel(struct('sf_ticks', 4), 'after', 3, 'tick')   % 1

  Voir aussi SFAFTER, SFBEFORE, SFAT, SFEVERY.
```

## `matlibre_sf_verite`

```
MATLIBRE_SF_VERITE Évalue une table de vérité de Stateflow.
  [S1,S2,...] = MATLIBRE_SF_VERITE(TABLE,E1,E2,...) pose les entrées,
  évalue chaque condition, prend la première décision dont les
  conditions s'accordent, fait son action et rend les sorties : c'est la
  fonction que bâtit SFTRUTHTABLE.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     t = struct('nom', 't', 'entrees', {{'x'}}, 'sorties', {{'y'}}, ...
                'conditions', {{'x > 0'}}, 'decisions', 'TF', ...
                'actions', {{'y = 1;', 'y = 2;'}});
     matlibre_sf_verite(t, 5)             % 1

  Voir aussi SFTRUTHTABLE.
```

## `sfafter`

```
SFAFTER Vrai après N réveils — ou N secondes — passés dans l'état.
  VRAI = SFAFTER(CONTEXTE,N) vaut vrai quand l'état dont on essaie la
  transition est actif depuis au moins N réveils du diagramme : c'est
  after(N, tick) de Stateflow. SFAFTER(CONTEXTE,N,'sec') compte en
  secondes : after(N, sec), pour un diagramme qui connaît le temps — le
  bloc Chart d'un schéma, ou un contexte qui porte l'instant sf_t.

  On l'écrit dans la garde d'une transition, qui reçoit le contexte :
     @(c, u) sfafter(c, 3)

  Exemple :
     m = sfchart('minuterie');
     m = sfstate(m, 'attente');
     m = sfstate(m, 'fini');
     m = sftransition(m, 'attente', 'fini', @(c, u) sfafter(c, 3));
     sfrun(m, zeros(1, 4))      % attente, attente, fini, fini

  Voir aussi SFBEFORE, SFAT, SFEVERY, SFSTEP.
```

## `sfat`

```
SFAT Vrai au N-ième réveil — ou à la N-ième seconde — passé dans l'état.
  VRAI = SFAT(CONTEXTE,N) vaut vrai au réveil où l'état dont on essaie
  la transition est actif depuis exactement N réveils : at(N, tick) de
  Stateflow. SFAT(CONTEXTE,N,'sec') compte en secondes, à la moitié
  d'un millionième près.

  Exemple :
     m = sfchart('impulsion');
     m = sfstate(m, 'bas');
     m = sfstate(m, 'haut');
     m = sftransition(m, 'bas', 'haut', @(c, u) sfat(c, 2));
     sfrun(m, zeros(1, 3))       % bas, haut, haut

  Voir aussi SFAFTER, SFBEFORE, SFEVERY.
```

## `sfbefore`

```
SFBEFORE Vrai avant N réveils — ou N secondes — passés dans l'état.
  VRAI = SFBEFORE(CONTEXTE,N) vaut vrai tant que l'état dont on essaie
  la transition est actif depuis moins de N réveils : before(N, tick) de
  Stateflow. SFBEFORE(CONTEXTE,N,'sec') compte en secondes.

  Exemple :
     m = sfchart('fenetre');
     m = sfstate(m, 'ouverte');
     m = sfstate(m, 'vue');
     m = sftransition(m, 'ouverte', 'vue', @(c, u) u == 1 && sfbefore(c, 2));
     sfrun(m, [0 0 1])          % ouverte, ouverte, ouverte : trop tard

  Voir aussi SFAFTER, SFAT, SFEVERY.
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

## `sfdecomposition`

```
SFDECOMPOSITION Rend les sous-états d'un état exclusifs ou parallèles.
  MACHINE = SFDECOMPOSITION(MACHINE,PARENT,'parallel') fait de PARENT
  un état à sous-états parallèles : quand il est actif, tous ses
  sous-états le sont, et chaque pas les exécute tour à tour, dans
  l'ordre où ils ont été déclarés. 'exclusive', le défaut, n'en laisse
  actif qu'un. PARENT vide désigne le diagramme lui-même.

  C'est la décomposition AND et OR de Stateflow : une machine qui surveille
  deux choses indépendantes en a deux régions parallèles, plutôt que le
  produit de leurs états.

  Exemple :
     m = sfchart('voiture');
     m = sfstate(m, 'phares');
     m = sfstate(m, 'phares.eteints');
     m = sfstate(m, 'phares.allumes');
     m = sfstate(m, 'moteur');
     m = sfstate(m, 'moteur.arret');
     m = sfstate(m, 'moteur.marche');
     m = sfdecomposition(m, '', 'parallel');
     sfstep(m, '', struct(), 0)      % {'phares.eteints', 'moteur.arret'}

  Voir aussi SFSTATE, SFHISTORY, SFSTEP.
```

## `sfdefault`

```
SFDEFAULT Choisit le sous-état où l'on entre par défaut.
  MACHINE = SFDEFAULT(MACHINE,ETAT) fait d'ETAT le sous-état où l'on
  entre quand on entre dans son parent sans en viser un : c'est la
  transition par défaut de Stateflow. Sans elle, c'est le premier
  sous-état déclaré. Pour un état du plus haut niveau, c'est l'état
  initial de la machine.

  Exemple :
     m = sfchart('feu');
     m = sfstate(m, 'rouge');
     m = sfstate(m, 'vert');
     m = sfdefault(m, 'vert');
     sfstep(m, '', struct(), 0)      % 'vert'

  Voir aussi SFSTATE, SFCHART, SFSTEP.
```

## `sfevent`

```
SFEVENT Déclare un événement d'entrée ou de sortie du diagramme.
  MACHINE = SFEVENT(MACHINE,NOM,'Input',DECLENCHEUR) déclare un
  événement d'entrée. Dans un bloc Chart, les événements d'entrée
  arrivent par un port de déclenchement, posé après les entrées de
  données, qui porte un élément par événement, dans l'ordre de leur
  déclaration. DECLENCHEUR dit ce qui fait l'événement :
     'Rising'         un front montant de son élément
     'Falling'        un front descendant
     'Either'         l'un ou l'autre
     'Function call'  un appel : l'élément non nul
  Un diagramme qui a des événements d'entrée ne calcule que quand l'un
  d'eux survient, une fois par événement : ses transitions étiquetées
  par cet événement peuvent alors partir, et celles sans événement
  aussi. Son premier réveil le fait entrer dans son état initial.

  MACHINE = SFEVENT(MACHINE,NOM,'Output',DECLENCHEUR) déclare un
  événement de sortie, qu'une action émet par « send(NOM) » ou par son
  nom seul, « NOM; ». Dans un bloc Chart, chaque événement de sortie a
  son port, après les sorties de données : 'Function call' (le défaut)
  y met 1 à l'instant où il est émis, de quoi appeler un sous-système
  appelé par fonction ; 'Either' y bascule entre 0 et 1 à chaque
  émission, un front que lit un sous-système déclenché.

  Les événements locaux ne sont pas pris en charge : SFEVENT les refuse.

  Exemple :
     m = sfchart('compteur');
     m = sfevent(m, 'impulsion', 'Input', 'Rising');
     m = sfevent(m, 'plein', 'Output', 'Function call');
     m = sfstate(m, 'compte', 'en: n = 0; du: n = n + 1;');
     m = sftransition(m, 'compte', 'compte', 'impulsion[n >= 3]{plein;}');
     numel(m.evenements)                % 2

  Voir aussi SFCHART, SFSTATE, SFTRANSITION, ADD_BLOCK.
```

## `sfevery`

```
SFEVERY Vrai tous les N réveils passés dans l'état.
  VRAI = SFEVERY(CONTEXTE,N) vaut vrai au N-ième réveil depuis qu'on est
  entré dans l'état, puis au 2N-ième, et ainsi de suite : every(N, tick)
  de Stateflow, qu'on écrit le plus souvent dans une action de séjour,
  ou dans la garde d'une transition vers soi.

  Exemple :
     m = sfchart('clignotant');
     m = sfstate(m, 'actif', [], @(c, u) setfield(c, 'coups', c.coups + sfevery(c, 2)));
     [~, c] = sfrun(m, zeros(1, 6), struct('coups', 0));
     c.coups                     % 3

  Voir aussi SFAFTER, SFAT.
```

## `sffunction`

```
SFFUNCTION Ajoute une fonction à la machine.
  MACHINE = SFFUNCTION(MACHINE,NOM,F) donne à la machine une fonction,
  comme une fonction graphique ou une fonction MATLAB d'un diagramme
  Stateflow : ses gardes et ses actions écrites en texte l'appellent par
  son nom. F est une poignée de fonction — @(x) 2*x, ou @mafonction.

  Exemple :
     m = sfchart('chauffe');
     m = sffunction(m, 'consigne', @(h) 18 + 2 * (h >= 8 && h < 22));
     m = sfstate(m, 'regle', 'du: c = consigne(u);');
     [~, c] = sfrun(m, [7 9]);
     c.c                          % 20

  Voir aussi SFTRUTHTABLE, SFSTATE, SFTRANSITION.
```

## `sfhistory`

```
SFHISTORY Donne un historique à un état : il revient où il était.
  MACHINE = SFHISTORY(MACHINE,PARENT) pose une jonction d'historique
  dans PARENT : quand on y rentre sans viser un de ses sous-états, on
  entre dans celui qu'on a quitté la dernière fois, au lieu du sous-état
  par défaut. PARENT vide désigne le diagramme lui-même.

  Exemple :
     m = sfchart('lecteur');
     m = sfstate(m, 'arret');
     m = sfstate(m, 'lecture');
     m = sfstate(m, 'lecture.piste1');
     m = sfstate(m, 'lecture.piste2');
     m = sfhistory(m, 'lecture');
     m = sftransition(m, 'lecture.piste1', 'lecture.piste2', @(c, u) u == 1);
     m = sftransition(m, 'lecture', 'arret', @(c, u) u == 2);
     m = sftransition(m, 'arret', 'lecture', @(c, u) u == 3);
     sfrun(m, [3 1 2 3])        % ... 'lecture.piste2' : l'historique

  Voir aussi SFSTATE, SFDECOMPOSITION, SFSTEP.
```

## `sfjunction`

```
SFJUNCTION Ajoute une jonction de connexion.
  MACHINE = SFJUNCTION(MACHINE,NOM) ajoute une jonction : un point où
  des transitions se rejoignent et se séparent, comme les jonctions de
  connexion de Stateflow. Une transition peut aller d'un état à une
  jonction, d'une jonction à une autre, et d'une jonction à un état.

  Une transition qui mène à une jonction n'est prise que si un chemin
  complet, fait de segments dont les gardes sont vraies, va de la
  jonction jusqu'à un état. Les segments qui partent d'une jonction
  s'essaient dans l'ordre de leur déclaration ; un segment sans garde
  est le chemin par défaut, et se déclare en dernier. Un segment dont
  la suite échoue est abandonné, et l'on essaie le suivant. Les actions
  de condition ({...}) s'exécutent à mesure que les gardes sont vraies ;
  les actions de transition, une fois le chemin trouvé, dans l'ordre des
  segments.

  Exemple :
     m = sfchart('tri');
     m = sfstate(m, 'attente');
     m = sfstate(m, 'petit');
     m = sfstate(m, 'grand');
     m = sfjunction(m, 'j');
     m = sftransition(m, 'attente', 'j', 'mesure');
     m = sftransition(m, 'j', 'petit', '[x < 10]');
     m = sftransition(m, 'j', 'grand', '');
     [h, c] = sfrun(m, {'rien', 'mesure'}, struct('x', 42));
     h{end}                      % 'grand'

  Voir aussi SFTRANSITION, SFSTATE, SFCHART.
```

## `sfrun`

```
SFRUN Exécute la machine sur une suite d'entrées.
  [HISTORIQUE,CONTEXTE] = SFRUN(MACHINE,ENTREES) rend la suite des états
  visités, un par pas, et le contexte final. SFRUN(MACHINE,ENTREES,
  CONTEXTE) part du contexte donné. SFRUN(MACHINE,ENTREES,CONTEXTE,
  INSTANTS) donne l'instant de chaque pas — celui du démarrage d'abord,
  puis un par entrée —, que lit la logique temporelle en secondes
  (SFAFTER(C,N,'sec')).

  La machine démarre dans son état initial, puis fait un pas par entrée,
  avec la règle de Stateflow que SFSTEP applique : une transition valide
  est prise — sortie, action de la transition, entrée —, sinon l'état
  exécute son action de séjour.

  Exemple :
     m = sfchart('tourniquet');
     m = sfstate(m, 'verrouille');
     m = sfstate(m, 'ouvert');
     m = sftransition(m, 'verrouille', 'ouvert', @(c,e) strcmp(e, 'piece'));
     sfrun(m, {'pousse', 'piece'})     % 'ouvert'

  Voir aussi SFSTEP, SFCHART, SFSTATE, SFTRANSITION.
```

## `sfstate`

```
SFSTATE Ajoute un état.
  MACHINE = SFSTATE(MACHINE,NOM,ENTREE,PENDANT,SORTIE) ajoute un état et
  ses trois actions, chacune une poignée qui prend le contexte et le
  rend modifié, ou un texte du langage d'action. Passer [] pour aucune
  action.

  MACHINE = SFSTATE(MACHINE,NOM,ETIQUETTE) donne les trois actions d'un
  seul texte, comme l'étiquette d'un état de Stateflow :
     'en: n = 0; du: n = n + u; ex: y = n;'
  Dans un texte, les champs du contexte sont des variables, u est
  l'entrée du pas, et toute variable posée devient un champ du contexte.
  La logique temporelle s'y écrit comme dans Stateflow : after(3, tick),
  before(0.5, sec), at(2, tick), every(4, tick).

  Les trois moments ne sont pas une question de style :
     ENTREE   s'exécute une fois, quand on entre dans l'état
     PENDANT  s'exécute à chaque pas passé dans l'état
     SORTIE   s'exécute une fois, quand on en sort

  Compter les fronts d'un signal demande une action d'entrée ; mesurer
  la durée d'un mode demande une action de séjour. Les confondre donne
  des comptes faux.

  Le premier état ajouté est l'état initial de la machine.

  Un nom « parent.enfant » fait un sous-état : son parent doit être
  déclaré avant lui, et le premier sous-état déclaré d'un parent est
  celui où l'on entre par défaut (SFDEFAULT en choisit un autre). Les
  états s'emboîtent ainsi à toute profondeur ; SFDECOMPOSITION rend les
  sous-états d'un parent parallèles, SFHISTORY lui donne un historique.

  Le contexte est une structure quelconque que la machine porte d'un pas
  à l'autre : c'est ce qui lui permet de compter, donc de dépasser la
  seule mémoire d'état.

  Exemple :
     m = sfchart('compteur');
     m = sfstate(m, 'compte', @(c) setfield(c, 'total', c.total + 1));
     [~, contexte] = sfrun(m, [1 0 1 0 1], struct('total', 0));
     m = sfstate(m, 'mesure', 'en: n = 0; du: n = n + u;');

  Voir aussi SFCHART, SFTRANSITION, SFRUN, SFDECOMPOSITION, SFHISTORY.
```

## `sfstep`

```
SFSTEP Fait faire un pas à une machine à états.
  [COURANT,CONTEXTE] = SFSTEP(MACHINE,COURANT,CONTEXTE,U) exécute un pas
  de la machine, comme Stateflow réveille un diagramme. Pour chaque état
  actif, du plus haut au plus profond : les transitions qui en partent
  sont essayées dans l'ordre où elles ont été déclarées, et la première
  dont la garde est vraie est prise — on sort de l'état et de ses
  sous-états (actions de sortie, du plus profond au plus haut), on
  exécute l'action de la transition, puis on entre dans la cible et dans
  ses sous-états par défaut (actions d'entrée, du plus haut au plus
  profond). Si aucune n'est vraie, l'état exécute son action de séjour,
  puis on descend dans ses sous-états actifs.

  Un état nommé « parent.enfant » est un sous-état : le premier déclaré
  de chaque parent est celui où l'on entre par défaut (SFDEFAULT en
  choisit un autre). Un parent en décomposition parallèle
  (SFDECOMPOSITION) a tous ses sous-états actifs à la fois ; un parent
  à historique (SFHISTORY) revient dans le sous-état qu'il a quitté.
  Une transition qui vise un parent entre dans son sous-état par défaut.

  COURANT est la feuille active — le sous-état le plus profond — ou,
  s'il y en a plusieurs, la cellule des feuilles actives. COURANT vide
  veut dire que la machine n'a pas encore démarré : le pas entre alors
  dans l'état initial et ses sous-états, et exécute leurs actions
  d'entrée.

  Le contexte porte, dans son champ sf_, ce que la machine doit se
  rappeler d'un pas à l'autre : les états actifs, le pas où chacun est
  devenu actif, l'historique. Avant d'essayer les transitions d'un état,
  le pas pose sf_ticks — le nombre de réveils depuis qu'on y est entré —
  et, si le contexte porte l'instant sf_t, sf_temps, la durée passée
  dedans : c'est ce que lisent SFAFTER, SFBEFORE, SFAT et SFEVERY.

  C'est le pas qu'exécutent SFRUN, sur une suite d'entrées, et le bloc
  Chart d'un schéma Simulink, à chaque instant d'échantillonnage.

  Exemple :
     m = sfchart('bascule');
     m = sfstate(m, 'bas');
     m = sfstate(m, 'haut');
     m = sftransition(m, 'bas', 'haut', @(c, u) u > 0.5);
     [e, c] = sfstep(m, '', struct(), 0);     % 'bas' : le démarrage
     [e, c] = sfstep(m, e, c, 1)               % 'haut'

  Voir aussi SFRUN, SFCHART, SFSTATE, SFTRANSITION, SFDECOMPOSITION,
  SFHISTORY, SFAFTER.
```

## `sftransition`

```
SFTRANSITION Ajoute une transition gardée.
  MACHINE = SFTRANSITION(MACHINE,DEPUIS,VERS,GARDE,ACTION) ajoute une
  transition entre deux états. GARDE est une poignée @(contexte,entree)
  qui rend vrai ou faux ; ACTION, facultative, une poignée @(contexte)
  qui rend le contexte modifié au passage.

  GARDE peut aussi être l'étiquette d'une transition de Stateflow, en
  texte : « evenement[condition]{action de condition} ». L'événement
  est vrai quand l'entrée du pas le nomme (un texte, ou une cellule de
  textes) ; la condition est une expression du langage d'action, où les
  champs du contexte sont des variables ; l'action de condition
  s'exécute dès que la condition est vraie, avant la sortie de l'état.
  Chaque partie est facultative : 'go', '[n >= 3]', 'go[n > 0]{k = 1;}',
  'go{k = 1;}', '[after(2, sec)]'. L'action de la transition s'écrit
  après une barre, comme dans Stateflow : 'go[n > 0]/fin = 1;' ; ACTION
  peut aussi la donner, en texte : 'fin = 1;'.

  Quand plusieurs transitions partent du même état, la première déclarée
  dont la garde est vraie l'emporte. C'est une règle de priorité, et il
  faut la connaître : elle décide du comportement quand deux conditions
  se recouvrent.

  Si aucune garde n'est vraie, la machine reste où elle est. Ne rien
  faire est un comportement, non une erreur.

  Exemple :
     m = sfchart('mesure');
     m = sfstate(m, 'depart');
     m = sfstate(m, 'petit');
     m = sfstate(m, 'grand');
     m = sftransition(m, 'depart', 'petit', @(c,e) e < 10);
     m = sftransition(m, 'depart', 'grand', @(c,e) e < 100);
     sfrun(m, 5)                     % 'petit' : la premiere gagne
     m = sftransition(m, 'petit', 'depart', 'raz[n > 0]{n = 0;}');

  Voir aussi SFCHART, SFSTATE, SFRUN.
```

## `sftruthtable`

```
SFTRUTHTABLE Ajoute une table de vérité à la machine.
  MACHINE = SFTRUTHTABLE(MACHINE,NOM,ENTREES,SORTIES,CONDITIONS,
  DECISIONS,ACTIONS) donne à la machine une fonction décrite, comme
  dans Stateflow, par une table de vérité :
     ENTREES      les noms de ses arguments, {'x', 'y'}
     SORTIES      les noms de ce qu'elle rend, {'z'} — zéro au départ
     CONDITIONS   une condition par ligne, écrite en texte sur les
                  entrées : {'x > 0', 'y == 1'}
     DECISIONS    une matrice de caractères, une ligne par condition,
                  une colonne par décision : 'T' la condition doit être
                  vraie, 'F' fausse, '-' peu importe
     ACTIONS      une action par décision, en texte, qui pose les
                  sorties : {'z = 1;', 'z = 2;', 'z = 0;'}
  Les décisions s'essaient de gauche à droite ; la première dont toutes
  les conditions s'accordent fait son action. Une colonne toute de '-'
  est la décision par défaut, et se met en dernier.

  Les gardes et les actions de la machine l'appellent par son nom.

  Exemple :
     m = sfchart('signe');
     m = sftruthtable(m, 'classe', {'x'}, {'k'}, {'x > 0', 'x < 0'}, ...
                      ['TF-'; 'FT-'], {'k = 1;', 'k = -1;', 'k = 0;'});
     m = sfstate(m, 'mesure', 'du: s = classe(u);');
     [~, c] = sfrun(m, [3 -2]);
     c.s                          % -1

  Voir aussi SFFUNCTION, SFSTATE, SFTRANSITION.
```

