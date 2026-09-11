# Toolbox `simulink`

```
% Simulink — simulation de schémas-blocs.
%
% Un modèle est une structure : une liste de blocs et une liste de liens.
% La simulation est à pas fixe et l'ordre d'exécution vient d'un tri
% topologique, si bien qu'une entrée est toujours calculée avant la sortie
% qui l'emploie. Les intégrateurs et les retards fournissent la mémoire,
% et cassent donc les boucles algébriques.
%
% Modèle
%   new_system  - Crée un modèle vide
%   add_block   - Ajoute un bloc, avec ses paramètres
%   add_line    - Relie une sortie à une entrée
%   set_param   - Change les paramètres d'un bloc
%
% Simulation
%   sim         - Simule à pas fixe ; rend temps et signaux
%   simplot     - Trace les signaux relevés
```

## `add_block`

```
ADD_BLOCK Ajoute un bloc au modèle.
  MODELE = ADD_BLOCK(MODELE,TYPE,NOM,'Param',VALEUR,...)

  Paramètres reconnus selon le type :
    constant     Value
    step         Time, Before, After
    ramp         Slope
    sine         Amplitude, Frequency, Phase
    gain         Gain
    sum          Signs (par exemple '+-')
    integrator   InitialCondition
    transferfcn  Numerator, Denominator
    statespace   A, B, C, D, X0
    saturation   UpperLimit, LowerLimit
    delay        InitialCondition
    relay        OnSwitch, OffSwitch, OnOutput, OffOutput

  Un bloc porte un nom, et c'est par ce nom qu'ADD_LINE le relie : le
  modèle n'est qu'une liste de blocs et d'arcs, dont SIM tire l'ordre de
  calcul.

  Exemple :
     m = new_system('rampe');
     m = add_block(m, 'constant', 'un', 'Value', 2);
     m = add_block(m, 'integrator', 'integ', 'InitialCondition', 0);
     numel(m.blocs)              % 2

  Voir aussi NEW_SYSTEM, ADD_LINE, SET_PARAM, SIM, SIMPLOT.
```

## `add_line`

```
ADD_LINE Relie la sortie d'un bloc à l'entrée d'un autre.
  MODELE = ADD_LINE(MODELE,'source','destination') relie la sortie du
  premier bloc à la première entrée du second.
  ADD_LINE(MODELE,'source','destination',NUMERO) choisit l'entrée, ce
  qui importe pour un bloc de somme dont les signes diffèrent.

  Une sortie peut alimenter plusieurs entrées : il suffit de plusieurs
  liens. Une entrée, non : le dernier lien posé l'emporterait.

  Une boucle est permise pourvu qu'un bloc à état — intégrateur ou
  retard — la coupe. Sans cela, la boucle est algébrique et le tri
  topologique n'a pas de solution.

  Exemple :
     m = new_system('boucle');
     m = add_block(m, 'constant', 'consigne', 'Value', 1);
     m = add_block(m, 'sum', 'erreur', 'Signs', '+-');
     m = add_block(m, 'gain', 'gain', 'Gain', 2);
     m = add_block(m, 'integrator', 'sortie', 'InitialCondition', 0);
     m = add_line(m, 'consigne', 'erreur', 1);
     m = add_line(m, 'sortie', 'erreur', 2);   % le retour
     m = add_line(m, 'erreur', 'gain');
     m = add_line(m, 'gain', 'sortie');

  Voir aussi ADD_BLOCK, NEW_SYSTEM, SIM.
```

## `find_system`

```
FIND_SYSTEM Les blocs d'un modèle, éventuellement filtrés.
  NOMS = FIND_SYSTEM(MODELE) rend le nom de tous les blocs.
  NOMS = FIND_SYSTEM(MODELE,'BlockType',TYPE) ne garde que ceux du type
  donné. D'autres couples nom-valeur filtrent sur les paramètres.

  Le filtre est conjonctif : un bloc n'est gardé que s'il répond à tous
  les critères. Sans critère, tous les blocs sortent.

  La comparaison est textuelle, y compris sur les valeurs numériques :
  un gain de 2 se retrouve aussi bien par 2 que par '2', puisque c'est
  ainsi qu'ADD_BLOCK accepte de l'écrire.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'gain', 'g1', 'Gain', 2);
     m = add_block(m, 'gain', 'g2', 'Gain', 3);
     m = add_block(m, 'constant', 'c', 'Value', 1);
     numel(find_system(m))                        % 3
     numel(find_system(m, 'BlockType', 'gain'))   % 2
     find_system(m, 'Gain', 3)                    % {'g2'}

  Voir aussi GET_PARAM, SET_PARAM, ADD_BLOCK, NEW_SYSTEM.
```

## `get_param`

```
GET_PARAM Lit un paramètre d'un bloc, ou la description d'un bloc.
  V = GET_PARAM(MODELE,NOM,'Param') rend la valeur du paramètre du bloc
  nommé. GET_PARAM(MODELE,NOM) rend la structure entière du bloc : son
  type, son nom et tous ses paramètres.
  GET_PARAM(MODELE,'Name') et GET_PARAM(MODELE,'Blocks') répondent sur
  le modèle lui-même.

  C'est le pendant de SET_PARAM, sans lequel on pouvait écrire un
  réglage sans jamais pouvoir le relire — et donc ni le vérifier, ni le
  sauvegarder, ni l'afficher.

  Un paramètre absent lève une erreur qui le nomme, plutôt que de rendre
  une valeur vide dont on ne saurait pas si elle est le réglage ou son
  absence.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'gain', 'g', 'Gain', 2);
     get_param(m, 'g', 'Gain')            % 2
     m = set_param(m, 'g', 'Gain', 5);
     get_param(m, 'g', 'Gain')            % 5
     get_param(m, 'g').type               % 'gain'

  Voir aussi SET_PARAM, ADD_BLOCK, FIND_SYSTEM, NEW_SYSTEM.
```

## `matlibre_meme_valeur`

```
MATLIBRE_MEME_VALEUR Compare deux valeurs de paramètre, texte ou nombre.
  Un paramètre de bloc s'écrit indifféremment en nombre ou en texte :
  ADD_BLOCK accepte « 'Gain', 2 » comme « 'Gain', '2' ». La recherche
  doit donc les tenir pour égaux, sans quoi retrouver un bloc dépendrait
  de la façon dont on l'a écrit.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_meme_valeur(2, '2')        % 1
     matlibre_meme_valeur('abc', 'abc')  % 1
     matlibre_meme_valeur(2, 3)          % 0

  Voir aussi FIND_SYSTEM, GET_PARAM.
```

## `new_system`

```
NEW_SYSTEM Crée un modèle Simulink vide.
  MODELE = NEW_SYSTEM(NOM) rend un modèle sans bloc ni lien. On le
  remplit par ADD_BLOCK, on le câble par ADD_LINE, on le règle par
  SET_PARAM, et on le simule par SIM.

  Le modèle est une structure à trois champs : NOM, BLOCS et LIENS.
  C'est une valeur, non une référence : chaque fonction en rend une
  nouvelle et laisse l'ancienne intacte.

  Les modèles se décrivent ici en appelant ces fonctions ; les fichiers
  .slx de MathWorks, dont le format n'est pas public, ne se lisent pas.

  Exemple :
     m = new_system('rampe');
     m = add_block(m, 'constant', 'un', 'Value', 2);
     m = add_block(m, 'integrator', 'integ', 'InitialCondition', 0);
     m = add_line(m, 'un', 'integ');
     r = sim(m, 5, 0.001);

  Voir aussi ADD_BLOCK, ADD_LINE, SET_PARAM, SIM, SIMPLOT.
```

## `set_param`

```
SET_PARAM Modifie les paramètres d'un bloc.
  MODELE = SET_PARAM(MODELE,NOM,'Param',VALEUR,...) change un ou
  plusieurs paramètres du bloc nommé, sans toucher aux autres ni au
  câblage.

  C'est ainsi qu'on balaie un réglage : construire le modèle une fois,
  puis le simuler pour chaque valeur d'un gain ou d'une condition
  initiale.

  Les noms de paramètres reconnus sont ceux qu'ADD_BLOCK décrit, par
  type de bloc. Un nom inconnu est simplement ajouté ; il ne sera lu par
  personne.

  Exemple :
     m = new_system('boucle');
     m = add_block(m, 'constant', 'consigne', 'Value', 1);
     m = add_block(m, 'sum', 'erreur', 'Signs', '+-');
     m = add_block(m, 'gain', 'gain', 'Gain', 2);
     m = add_block(m, 'integrator', 'sortie', 'InitialCondition', 0);
     m = add_line(m, 'consigne', 'erreur', 1);
     m = add_line(m, 'sortie', 'erreur', 2);
     m = add_line(m, 'erreur', 'gain');
     m = add_line(m, 'gain', 'sortie');
     for K = [1 2 5]
         m = set_param(m, 'gain', 'Gain', K);
         r = sim(m, 5, 0.01);
     end

  Voir aussi ADD_BLOCK, NEW_SYSTEM, SIM.
```

## `sim`

```
SIM Simule un modèle à pas fixe.
  RESULTAT = SIM(MODELE,TFINAL,PAS) rend une structure contenant le
  vecteur des instants et, pour chaque bloc, le signal relevé à sa
  sortie.
  SIM(MODELE,INSTANTS) accepte aussi un vecteur d'instants réguliers :
  il donne alors à la fois l'instant final et le pas.

  L'intégration se fait par la méthode d'Euler explicite ; les blocs
  sans état sont évalués dans l'ordre d'un tri topologique, ce qui
  garantit qu'une entrée est calculée avant la sortie qui l'utilise.
  Les intégrateurs et les retards fournissent la mémoire, et cassent
  donc les boucles algébriques.

  Tous les paramètres sont résolus avant la boucle : à l'intérieur, il
  ne reste que de l'arithmétique.

  SIM('NOM') accepte aussi le nom d'un modèle : une variable de
  l'espace de travail qui porte ce nom, ou un fichier NOM.m qui
  construit le modèle et le rend. Les modèles se décrivent ici en
  appelant NEW_SYSTEM, ADD_BLOCK et ADD_LINE ; les fichiers .slx de
  MathWorks, dont le format n'est pas public, ne se lisent pas.

  Le résultat porte les deux formes que Simulink journalise :
  RESULTAT.temps et RESULTAT.signaux.<nom> pour l'accès direct,
  RESULTAT.time et RESULTAT.signals(k).values pour la « structure with
  time » qu'attendent les scripts écrits pour Simulink.

  Exemple :
     m = new_system('rampe');
     m = add_block(m, 'constant', 'un', 'Value', 2);
     m = add_block(m, 'integrator', 'integ', 'InitialCondition', 0);
     m = add_line(m, 'un', 'integ');
     r = sim(m, 5, 0.001);
     abs(r.signaux.integ(end) - 10) < 0.01     % l'integrale de 2 sur 5 s

  Voir aussi NEW_SYSTEM, ADD_BLOCK, ADD_LINE, SIMPLOT.
```

## `simplot`

```
SIMPLOT Trace les signaux relevés par SIM.
  SIMPLOT(RESULTAT) trace tous les signaux du résultat sur le même axe,
  en fonction du temps. SIMPLOT(RESULTAT,NOMS) n'en trace que
  quelques-uns, désignés par leur nom de bloc.

  Exemple :
     m = new_system('boucle');
     m = add_block(m, 'constant', 'consigne', 'Value', 1);
     m = add_block(m, 'sum', 'erreur', 'Signs', '+-');
     m = add_block(m, 'gain', 'gain', 'Gain', 2);
     m = add_block(m, 'integrator', 'sortie', 'InitialCondition', 0);
     m = add_line(m, 'consigne', 'erreur', 1);
     m = add_line(m, 'sortie', 'erreur', 2);
     m = add_line(m, 'erreur', 'gain');
     m = add_line(m, 'gain', 'sortie');
     r = sim(m, 5, 0.01);
     simplot(r, {'consigne', 'sortie'});

  Voir aussi SIM, PLOT, LEGEND.
```

