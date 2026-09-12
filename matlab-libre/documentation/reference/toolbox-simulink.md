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

## `matlibre_sl_allure`

```
MATLIBRE_SL_ALLURE Dessine dans le bloc l'allure de ce qu'il produit.
  TRACE = MATLIBRE_SL_ALLURE(BLOC,X,Y,L,H) trace la petite courbe qui
  figure la fonction du bloc — l'échelon, la rampe, la sinusoïde, la
  saturation — et rend vrai si elle a été tracée.

  Un dessin dit d'un coup ce qu'un nom demande de lire. Les blocs sans
  allure connue rendent faux, et c'est alors leur étiquette qui parle.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     figure;
     matlibre_sl_allure(struct('type', 'step'), 0, 0, 1.7, 1)   % 1

  Voir aussi MATLIBRE_SL_FORME, MATLIBRE_SL_ETIQUETTE.
```

## `matlibre_sl_disposition`

```
MATLIBRE_SL_DISPOSITION Place les blocs d'un schéma sur la feuille.
  [X,Y,L,H] = MATLIBRE_SL_DISPOSITION(MODELE,RANGS) rend le centre de
  chaque bloc, ainsi que la largeur et la hauteur communes.

  Les blocs d'une même couche sont ordonnés par la hauteur moyenne de
  ceux qui les alimentent — le barycentre. Deux passes suffisent à
  défaire l'essentiel des croisements ; les ranger dans l'ordre de
  création en produirait à chaque embranchement.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('c');
     m = add_block(m, 'constant', 'u', 'Value', 1);
     m = add_block(m, 'gain', 'k', 'Gain', 2);
     m = add_line(m, 'u', 'k');
     [x, y] = matlibre_sl_disposition(m, matlibre_sl_rangs(m));
     x(2) > x(1)                     % 1 : le gain est a droite

  Voir aussi OPEN_SYSTEM, MATLIBRE_SL_RANGS.
```

## `matlibre_sl_etiquette`

```
MATLIBRE_SL_ETIQUETTE Ce qui s'écrit dans un bloc.
  TEXTE = MATLIBRE_SL_ETIQUETTE(BLOC) rend ce que le bloc affiche : sa
  valeur pour une constante, son gain pour un gain, sa transmittance
  pour un intégrateur ou un retard.

  C'est le réglage qui s'écrit, non le type : « 1/s » dit plus qu'
  « integrator », et un gain de 2 se lit d'un coup d'œil là où il
  faudrait sinon ouvrir le bloc.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_sl_etiquette(struct('type', 'integrator', 'parametres', struct()))

  Voir aussi MATLIBRE_SL_FORME, OPEN_SYSTEM, GET_PARAM.
```

## `matlibre_sl_fil`

```
MATLIBRE_SL_FIL Trace une liaison entre deux blocs, à angles droits.
  MATLIBRE_SL_FIL(DEPART,ARRIVEE) relie le point DEPART au point
  ARRIVEE par des segments horizontaux et verticaux, et pose une
  pointe de flèche à l'arrivée.

  MATLIBRE_SL_FIL(DEPART,ARRIVEE,true,BAS) trace un retour de boucle :
  la liaison descend sous le schéma, à la hauteur BAS, revient vers la
  gauche, puis remonte. Tracée en ligne droite, elle passerait au
  travers des blocs qu'elle enjambe.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     figure;
     matlibre_sl_fil([0 0], [3 1]);

  Voir aussi OPEN_SYSTEM, MATLIBRE_SL_FORME.
```

## `matlibre_sl_forme`

```
MATLIBRE_SL_FORME Dessine un bloc, selon ce qu'il fait.
  MATLIBRE_SL_FORME(BLOC,X,Y,L,H) trace le bloc centré en (X,Y).

  La forme dit la fonction avant que le texte ne la nomme : un gain est
  un triangle, une sommation un cercle, une source porte l'allure de
  son signal. C'est la convention des schémas-blocs, et elle se lit
  plus vite qu'une liste de rectangles étiquetés.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     figure;
     matlibre_sl_forme(struct('type', 'gain', 'nom', 'k', ...
                              'parametres', struct('Gain', 3)), 0, 0, 1.7, 1);

  Voir aussi OPEN_SYSTEM, MATLIBRE_SL_FIL.
```

## `matlibre_sl_pointe`

```
MATLIBRE_SL_POINTE Pointe de flèche à l'entrée d'un bloc.
  MATLIBRE_SL_POINTE(ARRIVEE) pose un petit triangle plein pointant
  vers la droite au point donné.

  Sans elle, un schéma-bloc ne dit pas dans quel sens l'information
  circule — et c'est précisément ce qu'un schéma-bloc sert à dire.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     figure;
     matlibre_sl_pointe([1 1]);

  Voir aussi MATLIBRE_SL_FIL, OPEN_SYSTEM.
```

## `matlibre_sl_rangs`

```
MATLIBRE_SL_RANGS Range les blocs en couches, de la source vers la sortie.
  [RANGS,RETOURS] = MATLIBRE_SL_RANGS(MODELE) rend le numéro de couche
  de chaque bloc et la liste des liens de rebouclage.

  Un schéma bouclé n'a pas d'ordre : le rangement se fait sur la partie
  sans circuit, et les liens qui referment une boucle sont mis à part
  pour être tracés en retour. C'est ce qui donne au schéma sa lecture
  de gauche à droite, la contre-réaction passant par-dessous.

  Le rang d'un bloc est la longueur du plus long chemin qui y mène :
  prendre le plus court tasserait les blocs contre leur source et
  ferait se croiser les liaisons.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('c');
     m = add_block(m, 'constant', 'u', 'Value', 1);
     m = add_block(m, 'gain', 'k', 'Gain', 2);
     m = add_line(m, 'u', 'k');
     matlibre_sl_rangs(m)            % [0 1]

  Voir aussi OPEN_SYSTEM, MATLIBRE_SL_DISPOSITION.
```

## `matlibre_sl_signes`

```
MATLIBRE_SL_SIGNES Signes d'un bloc de sommation.
  SIGNES = MATLIBRE_SL_SIGNES(BLOC) rend la chaîne des signes, « ++ »
  par défaut : une sommation sans signe déclaré additionne.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_sl_signes(struct('parametres', struct('Signs', '+-')))

  Voir aussi MATLIBRE_SL_FORME, ADD_BLOCK.
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

## `open_system`

```
OPEN_SYSTEM Ouvre un modèle et en dessine le schéma-bloc.
  OPEN_SYSTEM(MODELE) trace le schéma : un bloc par élément, sa forme
  disant ce qu'il fait, et les liaisons fléchées entre eux.
  H = OPEN_SYSTEM(MODELE) rend en plus la poignée de la figure.

  Les blocs sont rangés en couches, de la source vers la sortie, et
  ordonnés dans chaque couche pour croiser le moins de liaisons
  possible. Une contre-réaction passe sous le schéma : tracée en ligne
  droite, elle traverserait les blocs qu'elle enjambe.

  Le schéma est reconstruit à partir du modèle à chaque appel : il n'y
  a pas de position enregistrée, et donc rien à déplacer à la souris.
  MATLAB ouvre un éditeur, MatLibre rend une figure — on voit le
  schéma, on ne le modifie pas là.

  Exemple :
     m = new_system('boucle');
     m = add_block(m, 'constant', 'consigne', 'Value', 1);
     m = add_block(m, 'sum', 'erreur', 'Signs', '+-');
     m = add_block(m, 'gain', 'correcteur', 'Gain', 2);
     m = add_block(m, 'integrator', 'sortie', 'InitialCondition', 0);
     m = add_line(m, 'consigne', 'erreur', 1);
     m = add_line(m, 'sortie', 'erreur', 2);
     m = add_line(m, 'erreur', 'correcteur');
     m = add_line(m, 'correcteur', 'sortie');
     open_system(m);

  Voir aussi NEW_SYSTEM, ADD_BLOCK, ADD_LINE, SIM, SIMPLOT.
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

