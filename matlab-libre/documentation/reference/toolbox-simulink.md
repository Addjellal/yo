# Toolbox `simulink`

```
% Simulink — simulation de schémas-blocs.
%
% Un modèle est une structure : une liste de blocs, une liste de liens et
% quelques réglages. La simulation est à pas fixe et l'ordre d'exécution
% vient d'un tri topologique, si bien qu'une entrée est toujours calculée
% avant la sortie qui l'emploie. Les blocs sans transmission directe —
% intégrateur, retard, mémoire, retard pur — fournissent la mémoire, et
% cassent donc les boucles algébriques.
%
% Un modèle est une valeur, non une référence : chaque fonction en rend
% une nouvelle et laisse l'ancienne intacte.
%
% L'espace de travail est partagé, comme dans Simulink : un paramètre
% numérique écrit entre apostrophes est une expression, évaluée à la
% simulation — un gain réglé sur 'K' vaut ce que vaut K. Dans l'autre
% sens, le bloc « toworkspace » y dépose son signal et « fromworkspace »
% y lit le sien. Les fichiers .slx de
% MathWorks, dont le format n'est pas public, ne se lisent pas ;
% save_system écrit à leur place un programme .m qui rebâtit le modèle.
%
% Modèle
%   new_system    - Crée un modèle vide
%   open_system   - Dessine le schéma-bloc, et ouvre le modèle
%   close_system  - Ferme un modèle, et sa figure
%   bdclose       - Ferme un modèle, ou tous
%   bdroot        - Le nom du modèle
%   bdIsLoaded    - Dit si un modèle est ouvert
%   gcs           - Le nom du dernier modèle ouvert
%   getfullname   - Le chemin « modele/bloc » d'un bloc
%   save_system   - Écrit un .m qui rebâtit le modèle
%   load_system   - Relit ce .m
%
% Du schéma au programme
%   Deux chemins, qu'il ne faut pas confondre. SAVE_SYSTEM écrit le
%   programme qui rebâtit le modèle, et LOAD_SYSTEM le relit : c'est
%   l'aller-retour du schéma. MATLIBRE_SL_PROGRAMME, lui, écrit le
%   programme qui fait ce que le schéma fait — des variables, une boucle,
%   de l'arithmétique, aucun appel à Simulink — et il n'y a pas de
%   retour : on ne remonte pas d'un calcul quelconque au schéma qui
%   l'aurait produit. MATLIBRE_SL_ECRIRE le dépose dans un fichier.
%
% Un schéma dans un bloc
%   Un bloc de type « subsystem » porte tout un modèle, bâti comme les
%   autres. Ses blocs INPORT sont ses entrées, son premier OUTPORT sa
%   sortie ; SIM le déplie avant de simuler, si bien qu'il rend
%   exactement ce que rendrait le schéma écrit à plat. Le relevé porte
%   ses blocs sous le nom « sousSysteme/bloc », et le sous-système
%   lui-même porte la valeur de sa sortie. Ils s'emboîtent.
%
% Le solveur
%   L'intégration se fait à pas fixe. ode1 (Euler explicite) est celui
%   par défaut ; ode2, ode3 et ode4 évaluent la dérivée en des points
%   intermédiaires du pas et gagnent un ordre à chaque fois. Ils ne
%   valent que pour un état continu : un modèle qui porte un retard ou
%   un bloc échantillonné est refusé en nommant le bloc, plutôt
%   qu'intégré de travers. SIMSET le choisit, ADD_PARAM le pose sur le
%   modèle.
%
% Blocs et liens
%   add_block     - Ajoute un bloc, avec ses paramètres
%   delete_block  - Retire un bloc, et les liens qui y touchent
%   replace_block - Change le type de tous les blocs d'un type
%   add_line      - Relie une sortie à une entrée
%   delete_line   - Supprime un lien
%   find_system   - Les blocs, éventuellement filtrés
%
% Réglages
%   get_param     - Lit un paramètre de bloc, ou du modèle
%   set_param     - Change les paramètres d'un bloc, ou du modèle
%   add_param     - Pose un réglage sur le modèle
%   delete_param  - Retire un réglage du modèle
%
% Simulation
%   sim           - Simule à pas fixe ; rend temps et signaux
%   simset        - Rassemble les options d'une simulation
%   simget        - Lit une option
%   simplot       - Trace les signaux relevés
%
% Linéarisation
%   linmod        - Linéarise autour d'un point de fonctionnement
%   dlinmod       - Linéarise et échantillonne
%   trim          - Cherche un point d'équilibre
```

## `add_block`

```
ADD_BLOCK Ajoute un bloc au modèle.
  MODELE = ADD_BLOCK(MODELE,TYPE,NOM,'Param',VALEUR,...)

  Sources — elles n'ont pas d'entrée :
    constant     Value
    step         Time, Before, After
    ramp         Slope
    sine         Amplitude, Frequency, Phase
    inport       Port, Value          l'entrée du modèle, vue par LINMOD

  Opérations sans mémoire :
    gain         Gain
    bias         Bias
    sum          Signs (par exemple '+-')
    product      —                    le produit de toutes ses entrées
    abs          —
    sign         —
    math         Operator : square, sqrt, exp, log, reciprocal
    trigonometry Operator : sin, cos, tan, asin, acos, atan, atan2,
                 sinh, cosh, tanh, asinh, acosh, atanh
    minmax       Function : min ou max, sur toutes les entrées
    logic        Operator : AND, OR, NAND, NOR, XOR, NXOR, NOT
    relational   Operator : ==, ~=, <, <=, >, >=
    switch       Threshold, Criteria : 'u2>=Threshold', 'u2>Threshold',
                 'u2~=0' — la première entrée passe, ou la troisième
    saturation   UpperLimit, LowerLimit
    deadzone     UpperValue, LowerValue
    quantizer    QuantizationInterval
    lookup       BreakpointsData, TableData
    outport      Port                 la sortie du modèle

  Blocs à mémoire — ce sont eux qui coupent les boucles :
    integrator   InitialCondition
    delay        InitialCondition     aussi nommé unitdelay
    memory       InitialCondition     la valeur du pas précédent
    transportdelay DelayTime, InitialOutput
    derivative   —                    transmission directe : ne coupe rien
    relay        OnSwitch, OffSwitch, OnOutput, OffOutput
    ratelimiter  RisingSlewLimit, FallingSlewLimit, InitialOutput
    transferfcn  Numerator, Denominator
    statespace   A, B, C, D, X0
    pidcontroller P, I, D, N          dérivée filtrée par N/(1+N/s)

  Blocs échantillonnés — ils ne relisent leur entrée qu'à leur période :
    zoh                  SampleTime   aussi nommé zeroorderhold
    discreteintegrator   Gain, SampleTime, InitialCondition,
                         IntegratorMethod : ForwardEuler, BackwardEuler,
                         Trapezoidal
    discretetransferfcn  Numerator, Denominator, SampleTime
    discretestatespace   A, B, C, D, X0, SampleTime

  Passe-plat, pour la lisibilité du schéma : scope, mux, demux,
  terminator, display, toworkspace, fromworkspace, signalconversion,
  goto, from.

  Un schéma dans un bloc :
    subsystem    Model                un modèle entier, abrégé en un bloc

  Le sous-système porte le modèle qu'il abrège, bâti comme les autres
  par NEW_SYSTEM. Ses blocs INPORT sont ses entrées, dans l'ordre de
  leur paramètre Port, et son premier OUTPORT est sa sortie. SIM le
  déplie avant de simuler : le résultat est exactement celui du schéma
  écrit à plat, et le relevé porte à la fois le sous-système — la
  valeur de sa sortie — et chacun de ses blocs, sous le nom
  « sousSysteme/bloc ». Les sous-systèmes s'emboîtent.

  Un type inconnu est refusé. Le laisser passer donnerait une
  simulation qui tourne et un résultat faux.

  Un bloc porte un nom, et c'est par ce nom qu'ADD_LINE le relie : le
  modèle n'est qu'une liste de blocs et d'arcs, dont SIM tire l'ordre de
  calcul.

  Tout bloc accepte en outre POSITION, [gauche haut droite bas] comme
  dans Simulink : il garde alors la place qu'on lui donne, au lieu
  d'être rangé par couches. C'est ainsi qu'un schéma déplacé à la
  souris dans l'éditeur du bureau se retient — l'ordonnée y descend,
  comme sur un écran.

  Un paramètre numérique donné entre apostrophes est une expression,
  évaluée dans l'espace de travail de base au moment où l'on simule —
  comme dans Simulink. C'est ainsi qu'un modèle et un programme
  partagent leurs variables :

     K = 4;
     m = add_block(m, 'gain', 'k', 'Gain', 'K');   % non pas 4, mais K
     r = sim(m, 1, 0.01);                          % le gain vaut 4
     K = 10; r = sim(m, 1, 0.01);                  % il vaut 10

  Le modèle, lui, n'a pas bougé : il porte toujours l'expression, et
  c'est elle que le schéma affiche. Les paramètres qui sont du texte —
  Signs, Operator, Criteria, Function, IntegratorMethod, VariableName —
  restent lus tels quels.

  Exemple :
     m = new_system('rampe');
     m = add_block(m, 'constant', 'un', 'Value', 2);
     m = add_block(m, 'integrator', 'integ', 'InitialCondition', 0);
     numel(m.blocs)              % 2

  Voir aussi NEW_SYSTEM, ADD_LINE, SET_PARAM, DELETE_BLOCK, SIM, OPEN_SYSTEM.
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

## `add_param`

```
ADD_PARAM Pose un réglage sur le modèle lui-même.
  MODELE = ADD_PARAM(MODELE,'Nom',VALEUR,...) ajoute un ou plusieurs
  réglages au modèle. Ce ne sont pas les paramètres d'un bloc : ils
  valent pour la simulation entière.

  Trois sont lus par SIM quand l'appel ne les donne pas :
    StopTime    l'instant final
    FixedStep   le pas d'intégration
    Solver      le solveur : ode1, ode2, ode3 ou ode4

  Un réglage déjà posé est refusé en le nommant : c'est SET_PARAM qui
  le change, comme dans MATLAB, où ADD_PARAM ne sert qu'à créer.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'constant', 'c', 'Value', 3);
     m = add_param(m, 'StopTime', 2, 'FixedStep', 0.5);
     r = sim(m);
     r.temps(end)                     % 2
     numel(r.temps)                   % 5 : de 0 a 2 par pas de 0,5

  Voir aussi DELETE_PARAM, SET_PARAM, GET_PARAM, NEW_SYSTEM, SIM.
```

## `bdIsLoaded`

```
BDISLOADED Dit si un modèle est ouvert dans la session.
  R = BDISLOADED(NOM) rend vrai si un modèle de ce nom a été ouvert par
  OPEN_SYSTEM ou LOAD_SYSTEM et pas encore fermé.

  Exemple :
     bdclose('all');
     m = new_system('essai');
     bdIsLoaded('essai')              % faux : construit n'est pas ouvert
     open_system(m);
     bdIsLoaded('essai')              % vrai
     bdclose('all');

  Voir aussi OPEN_SYSTEM, CLOSE_SYSTEM, BDCLOSE, GCS, LOAD_SYSTEM.
```

## `bdclose`

```
BDCLOSE Ferme un modèle, ou tous.
  BDCLOSE(NOM) retire du registre le modèle nommé. BDCLOSE('all') les
  retire tous. BDCLOSE() sans argument ferme le dernier ouvert.

  Fermer ne détruit pas la valeur : la variable qui porte le modèle
  reste, et un nouvel OPEN_SYSTEM le rouvre. C'est le registre de la
  session qui se vide, celui que lisent GCS et BDISLOADED.

  Exemple :
     m = new_system('essai');
     open_system(m);
     bdclose('essai');
     bdIsLoaded('essai')              % faux

  Voir aussi CLOSE_SYSTEM, OPEN_SYSTEM, BDISLOADED, GCS.
```

## `bdroot`

```
BDROOT Le nom du modèle.
  NOM = BDROOT(MODELE) rend le nom du modèle. BDROOT() sans argument
  rend celui du dernier modèle ouvert par OPEN_SYSTEM.

  Dans MATLAB, BDROOT remonte du bloc courant jusqu'au modèle qui le
  contient. Ici un modèle est une valeur qu'on tient dans une variable,
  et non un objet ouvert dans une fenêtre : il n'y a rien à remonter,
  sinon le nom.

  Exemple :
     m = new_system('asservissement');
     bdroot(m)                        % 'asservissement'

  Voir aussi NEW_SYSTEM, GCS, OPEN_SYSTEM, FIND_SYSTEM.
```

## `close_system`

```
CLOSE_SYSTEM Ferme un modèle, en l'enregistrant au besoin.
  CLOSE_SYSTEM(MODELE) retire le modèle du registre de la session et
  ferme la figure que OPEN_SYSTEM avait tracée, s'il y en avait une.
  CLOSE_SYSTEM(MODELE,FICHIER) l'enregistre d'abord, par SAVE_SYSTEM.
  CLOSE_SYSTEM(NOM) accepte aussi le nom d'un modèle ouvert, et
  CLOSE_SYSTEM() sans argument ferme le dernier ouvert.

  Fermer ne détruit pas la valeur : la variable qui porte le modèle
  reste. C'est le registre de la session qui se vide, celui que lisent
  GCS et BDISLOADED.

  Exemple :
     m = new_system('essai');
     open_system(m);
     close_system(m);
     bdIsLoaded('essai')              % faux

  Voir aussi OPEN_SYSTEM, BDCLOSE, SAVE_SYSTEM, GCS.
```

## `delete_block`

```
DELETE_BLOCK Retire un bloc du modèle, et les liens qui y touchent.
  MODELE = DELETE_BLOCK(MODELE,NOM) enlève le bloc nommé. Les liens qui
  partaient de lui ou arrivaient à lui disparaissent avec lui : laisser
  un lien vers un bloc absent rendrait le modèle insimulable.

  Les blocs qui suivent sont renumérotés, puisque les liens désignent
  les blocs par leur rang. C'est transparent : on désigne toujours un
  bloc par son nom.

  Comme ADD_BLOCK, la fonction rend un nouveau modèle et laisse
  l'ancien intact : un modèle est ici une valeur, non une référence.
  Dans MATLAB, DELETE_BLOCK modifie le modèle ouvert et ne rend rien.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'constant', 'c', 'Value', 1);
     m = add_block(m, 'gain', 'g', 'Gain', 2);
     m = add_line(m, 'c', 'g');
     m = delete_block(m, 'g');
     numel(m.blocs)                       % 1
     isempty(m.liens)                     % le lien est parti avec le bloc

  Voir aussi ADD_BLOCK, DELETE_LINE, REPLACE_BLOCK, FIND_SYSTEM.
```

## `delete_line`

```
DELETE_LINE Supprime le lien qui va d'un bloc à un autre.
  MODELE = DELETE_LINE(MODELE,SOURCE,DESTINATION) supprime le lien
  allant de la sortie du premier bloc à l'entrée du second.
  DELETE_LINE(MODELE,SOURCE,DESTINATION,NUMERO) précise laquelle des
  entrées, quand plusieurs liens joignent les deux mêmes blocs.

  Un lien qui n'existe pas lève une erreur qui nomme les deux blocs,
  plutôt que de laisser croire à une suppression qui n'a pas eu lieu.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'constant', 'c', 'Value', 1);
     m = add_block(m, 'gain', 'g', 'Gain', 2);
     m = add_line(m, 'c', 'g');
     m = delete_line(m, 'c', 'g');
     isempty(m.liens)                 % vrai

  Voir aussi ADD_LINE, DELETE_BLOCK, NEW_SYSTEM.
```

## `delete_param`

```
DELETE_PARAM Retire un réglage du modèle.
  MODELE = DELETE_PARAM(MODELE,'Nom',...) enlève un ou plusieurs
  réglages posés par ADD_PARAM. Le modèle retrouve alors le
  comportement par défaut : SIM reprend ses dix secondes et son
  centième de seconde.

  Un réglage absent est refusé en le nommant, plutôt que passé sous
  silence : croire avoir retiré ce qui n'y était pas mène à chercher
  longtemps pourquoi rien n'a changé.

  Exemple :
     m = new_system('essai');
     m = add_param(m, 'StopTime', 2);
     m = delete_param(m, 'StopTime');
     isfield(m.parametres, 'StopTime')        % faux

  Voir aussi ADD_PARAM, SET_PARAM, GET_PARAM, NEW_SYSTEM.
```

## `dlinmod`

```
DLINMOD Linéarise un modèle et l'échantillonne à la période TS.
  [A,B,C,D] = DLINMOD(MODELE,TS) linéarise le modèle comme LINMOD, puis
  discrétise le résultat par bloqueur d'ordre zéro : l'entrée est tenue
  constante entre deux instants d'échantillonnage.
  [A,B,C,D] = DLINMOD(MODELE,TS,X,U) choisit le point de
  fonctionnement ; PARA joue le même rôle que dans LINMOD.
  SYS = DLINMOD(...) rend la structure à champs a, b, c, d.

  La discrétisation est exacte, non approchée : Ad et Bd sortent d'une
  seule exponentielle de matrice, celle de [A B ; 0 0]*TS, dont le bloc
  supérieur droit vaut l'intégrale de exp(A t) B — ce qui évite d'avoir
  à inverser A, qui est souvent singulière.

  TS nul rend la linéarisation continue elle-même, comme dans MATLAB.

  Exemple :
     m = new_system('premier');
     m = add_block(m, 'inport', 'u', 'Port', 1);
     m = add_block(m, 'sum', 's', 'Signs', '+-');
     m = add_block(m, 'integrator', 'x');
     m = add_block(m, 'outport', 'y', 'Port', 1);
     m = add_line(m, 'u', 's', 1);
     m = add_line(m, 'x', 's', 2);
     m = add_line(m, 's', 'x');
     m = add_line(m, 'x', 'y');
     [Ad, Bd] = dlinmod(m, 0.5);
     abs(Ad - exp(-0.5)) < 1e-12          % le pole continu -1

  Voir aussi LINMOD, TRIM, C2D, SIM.
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

## `gcs`

```
GCS Le nom du dernier modèle ouvert.
  NOM = GCS() rend le nom du modèle ouvert le plus récemment par
  OPEN_SYSTEM ou LOAD_SYSTEM, et une chaîne vide si aucun ne l'est.

  Dans MATLAB, GCS rend le système courant, celui dont la fenêtre a le
  focus. Il n'y a pas de fenêtre ici, et la notion la plus proche est
  celle du dernier modèle ouvert : c'est ce que rend GCS.

  Exemple :
     bdclose('all');
     m = new_system('regulateur');
     open_system(m);
     gcs()                            % 'regulateur'
     bdclose('all');

  Voir aussi OPEN_SYSTEM, CLOSE_SYSTEM, BDROOT, BDISLOADED.
```

## `get_param`

```
GET_PARAM Lit un paramètre d'un bloc, ou la description d'un bloc.
  V = GET_PARAM(MODELE,NOM,'Param') rend la valeur du paramètre du bloc
  nommé. GET_PARAM(MODELE,NOM) rend la structure entière du bloc : son
  type, son nom et tous ses paramètres.
  GET_PARAM(MODELE,'Name') et GET_PARAM(MODELE,'Blocks') répondent sur
  le modèle lui-même, ainsi que tout réglage posé par ADD_PARAM —
  StopTime, FixedStep — quand aucun bloc ne porte ce nom.

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
     m = add_param(m, 'StopTime', 4);
     get_param(m, 'StopTime')             % 4

  Voir aussi SET_PARAM, ADD_PARAM, ADD_BLOCK, FIND_SYSTEM, NEW_SYSTEM.
```

## `getfullname`

```
GETFULLNAME Le chemin complet d'un bloc, « modele/bloc ».
  CHEMIN = GETFULLNAME(MODELE,NOM) rend 'modele/bloc', la forme sous
  laquelle Simulink désigne un bloc. GETFULLNAME(MODELE) rend le nom du
  modèle seul.

  Le bloc doit exister : un chemin vers un bloc absent se propagerait
  sans erreur jusqu'à l'endroit où il ne veut rien dire.

  Exemple :
     m = new_system('boucle');
     m = add_block(m, 'gain', 'k', 'Gain', 2);
     getfullname(m, 'k')              % 'boucle/k'

  Voir aussi FIND_SYSTEM, GET_PARAM, BDROOT, NEW_SYSTEM.
```

## `linmod`

```
LINMOD Linéarise un modèle autour d'un point de fonctionnement.
  [A,B,C,D] = LINMOD(MODELE) linéarise le modèle autour de l'état nul
  et de l'entrée nulle. Les entrées sont les blocs INPORT, classés par
  leur paramètre Port ; les sorties, les blocs OUTPORT ; les états, les
  intégrateurs et les représentations d'état, dans l'ordre du modèle.

  [A,B,C,D] = LINMOD(MODELE,X,U) choisit le point de fonctionnement.
  [A,B,C,D] = LINMOD(MODELE,X,U,PARA) donne dans PARA(3) le pas de
  perturbation, et dans PARA(1) le pas de simulation employé pour
  relever les signaux.
  SYS = LINMOD(...) rend une structure à champs a, b, c, d, StateName,
  InputName et OutputName, comme MATLAB.

  La linéarisation est numérique, par différences centrées : elle est
  donc exacte, à l'arrondi près, sur un modèle déjà linéaire. Sur un
  bloc à cassure — saturation, zone morte, relais, aiguillage — elle
  rend la pente locale, et n'a pas de sens au point de cassure même.

  Un bloc DERIVATIVE est refusé : sa sortie dépend du pas de calcul,
  si bien que sa linéarisation dépendrait d'un réglage du simulateur
  plutôt que du modèle.

  Exemple :
     m = new_system('deuxieme');
     m = add_block(m, 'inport', 'u', 'Port', 1);
     m = add_block(m, 'sum', 's', 'Signs', '+-');
     m = add_block(m, 'integrator', 'v');
     m = add_block(m, 'integrator', 'p');
     m = add_block(m, 'gain', 'k', 'Gain', 4);
     m = add_block(m, 'outport', 'y', 'Port', 1);
     m = add_line(m, 'u', 's', 1);
     m = add_line(m, 'k', 's', 2);
     m = add_line(m, 's', 'v');
     m = add_line(m, 'v', 'p');
     m = add_line(m, 'p', 'k');
     m = add_line(m, 'p', 'y');
     [A, B, C, D] = linmod(m);
     A                                   % [0 -4 ; 1 0]

  Voir aussi DLINMOD, TRIM, SIM, SS.
```

## `load_system`

```
LOAD_SYSTEM Relit un modèle enregistré, et l'ouvre dans la session.
  MODELE = LOAD_SYSTEM(NOM) exécute le fichier NOM.m — celui qu'écrit
  SAVE_SYSTEM, ou tout autre programme qui rend un modèle — et rend le
  modèle obtenu. Le modèle est inscrit au registre de la session :
  BDISLOADED répond vrai, et GCS le nomme.

  Le chemin peut porter l'extension .m ou non. Un fichier .slx ou .mdl
  est refusé en disant pourquoi : leur format n'est pas public.

  Exemple :
     m = new_system('petit');
     m = add_block(m, 'constant', 'c', 'Value', 7);
     chemin = save_system(m, [tempname() '.m']);
     relu = load_system(chemin);
     get_param(relu, 'c', 'Value')            % 7
     bdclose('petit');
     delete(chemin);

  Voir aussi SAVE_SYSTEM, OPEN_SYSTEM, BDISLOADED, GCS, SIM.
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

## `matlibre_sl_aplatir`

```
MATLIBRE_SL_APLATIR Déplie les sous-systèmes d'un modèle.
  MODELE = MATLIBRE_SL_APLATIR(MODELE) rend le même modèle, où chaque
  bloc de type « subsystem » a été remplacé par les blocs qu'il
  contient. Un modèle sans sous-système est rendu tel quel.

  C'est ainsi qu'un sous-système se simule : non pas comme un bloc à
  part, mais comme le schéma qu'il abrège. SIM, LINMOD, TRIM et
  MATLIBRE_SL_PROGRAMME appellent tous cette fonction d'abord, si bien
  qu'aucun d'eux n'a besoin de savoir qu'un sous-système existe.

  Le dépliage garde trois choses. Les blocs intérieurs prennent le nom
  « sousSysteme/bloc », comme dans Simulink, et se retrouvent donc
  nommés dans le relevé. Le bloc du sous-système lui-même ne
  disparaît pas : il reste, en passe-plat, portant la valeur de son
  premier OUTPORT — un relevé pris sur le sous-système reste donc
  celui de sa sortie. Et les entrées se raccordent par leur rang : le
  lien qui arrivait sur la deuxième entrée du bloc arrive sur le bloc
  INPORT intérieur dont le paramètre Port vaut 2.

  Les sous-systèmes s'emboîtent : un sous-système qui en contient un
  autre est déplié jusqu'au bout.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     interne = new_system('doubleur');
     interne = add_block(interne, 'inport', 'e', 'Port', 1);
     interne = add_block(interne, 'gain', 'deux', 'Gain', 2);
     interne = add_block(interne, 'outport', 's', 'Port', 1);
     interne = add_line(add_line(interne, 'e', 'deux'), 'deux', 's');
     m = add_block(new_system('dehors'), 'constant', 'un', 'Value', 3);
     m = add_block(m, 'subsystem', 'boite', 'Model', interne);
     m = add_line(m, 'un', 'boite');
     numel(matlibre_sl_aplatir(m).blocs)      % 5 : un, boite, e, deux, s

  Voir aussi SIM, ADD_BLOCK, MATLIBRE_SL_ORDRE.
```

## `matlibre_sl_charger`

```
MATLIBRE_SL_CHARGER Relit un modèle et le dépose dans l'espace de travail.
  NOM = MATLIBRE_SL_CHARGER(CHEMIN) exécute le fichier .m qui bâtit un
  modèle — celui qu'écrit SAVE_SYSTEM — et pose le modèle obtenu dans
  l'espace de travail de base, sous son propre nom. Il rend ce nom.

  C'est ce que fait l'éditeur du bureau quand on ouvre un modèle : il
  ne garde pas le modèle pour lui, il le met là où tout le monde le
  voit — la console, l'explorateur de variables, et l'éditeur.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = add_block(new_system('reprise'), 'gain', 'k', 'Gain', 2);
     chemin = save_system(m, [tempname() '.m']);
     nom = matlibre_sl_charger(chemin);
     strcmp(nom, 'reprise')                  % 1
     delete(chemin);

  Voir aussi LOAD_SYSTEM, SAVE_SYSTEM, OPEN_SYSTEM.
```

## `matlibre_sl_dedans`

```
MATLIBRE_SL_DEDANS Le modèle que porte un sous-système, au bout d'un chemin.
  SOUS = MATLIBRE_SL_DEDANS(MODELE,CHEMIN) descend dans les
  sous-systèmes que CHEMIN désigne — « boite » pour un seul niveau,
  « boite/interne » pour deux — et rend le modèle trouvé au bout. Un
  chemin vide rend le modèle lui-même.

  C'est ainsi que l'éditeur du bureau ouvre un sous-système : il ne le
  recopie pas, il le désigne. MATLIBRE_SL_REMPLACER fait le chemin
  inverse, et repose dessous ce qu'on y a modifié.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     interne = add_block(new_system('dedans'), 'gain', 'k', 'Gain', 3);
     m = add_block(new_system('dehors'), 'subsystem', 'boite', ...
                   'Model', interne);
     matlibre_sl_dedans(m, 'boite').nom          % 'dedans'

  Voir aussi MATLIBRE_SL_REMPLACER, MATLIBRE_SL_APLATIR, ADD_BLOCK.
```

## `matlibre_sl_derivee`

```
MATLIBRE_SL_DERIVEE Dérivée d'état et sortie d'un modèle en un point.
  [DX,Y] = MATLIBRE_SL_DERIVEE(MODELE,X,U,PAS) place les états
  continus à X et les entrées à U, simule un seul instant, et relève la
  dérivée de chaque état ainsi que la valeur de chaque sortie.

  La dérivée ne se mesure pas : elle se lit. L'entrée d'un intégrateur
  est sa dérivée, et le simulateur relève déjà la sortie de chaque
  bloc. Pour une représentation d'état, c'est A x + B u, calculé sur
  l'entrée relevée.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('chaine');
     m = add_block(m, 'inport', 'u', 'Port', 1);
     m = add_block(m, 'gain', 'k', 'Gain', 3);
     m = add_block(m, 'integrator', 'x');
     m = add_line(m, 'u', 'k');
     m = add_line(m, 'k', 'x');
     matlibre_sl_derivee(m, 0, 2, 1e-3)     % 6 : la dérivée vaut 3*u

  Voir aussi LINMOD, DLINMOD, TRIM, SIM.
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

## `matlibre_sl_ecrire`

```
MATLIBRE_SL_ECRIRE Écrit dans un fichier le programme qui simule un schéma.
  CHEMIN = MATLIBRE_SL_ECRIRE(MODELE,CHEMIN) écrit à cet endroit le
  programme que rend MATLIBRE_SL_PROGRAMME, et rend le chemin écrit.
  L'extension .m est ajoutée si elle manque, et le nom de la fonction
  est celui du fichier — sans quoi elle ne s'appellerait pas.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = add_block(new_system('petit'), 'constant', 'c', 'Value', 1);
     f = matlibre_sl_ecrire(m, [tempname() '.m']);
     isfile(f)                                % 1
     delete(f);

  Voir aussi MATLIBRE_SL_PROGRAMME, SAVE_SYSTEM.
```

## `matlibre_sl_etats`

```
MATLIBRE_SL_ETATS Recense les états continus, les entrées et les sorties.
  [BLOCS,RANGS,ENTREES,SORTIES] = MATLIBRE_SL_ETATS(MODELE) rend, pour
  chaque bloc à état continu, son rang dans le modèle (BLOCS) et le
  rang des composantes d'état qu'il porte dans le vecteur global
  (RANGS, une cellule par bloc). ENTREES et SORTIES rendent les rangs
  des blocs INPORT et OUTPORT, classés par leur paramètre Port.

  Seuls l'intégrateur et la représentation d'état — donc aussi la
  fonction de transfert, qui s'y ramène — portent un état continu.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('chaine');
     m = add_block(m, 'inport', 'u', 'Port', 1);
     m = add_block(m, 'integrator', 'x');
     m = add_block(m, 'outport', 'y', 'Port', 1);
     m = add_line(m, 'u', 'x');
     m = add_line(m, 'x', 'y');
     [b, r] = matlibre_sl_etats(m);
     numel(b)                          % 1 : un seul etat

  Voir aussi LINMOD, DLINMOD, TRIM, SIM.
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

## `matlibre_sl_expression`

```
MATLIBRE_SL_EXPRESSION Évalue un paramètre de bloc donné par une expression.
  V = MATLIBRE_SL_EXPRESSION(TEXTE,BLOC,PARAMETRE) évalue TEXTE dans
  l'espace de travail de base et rend sa valeur numérique.

  C'est ainsi qu'un modèle et l'espace de travail partagent leurs
  variables : un gain réglé à 'K' vaut ce que vaut K au moment où l'on
  simule, non ce qu'il valait quand on a posé le bloc. Changer K et
  relancer SIM suffit ; le modèle, lui, ne bouge pas.

  L'espace consulté est celui de base, comme dans Simulink : un modèle
  ne voit pas les variables locales de la fonction qui le simule.

  Une expression qui ne s'évalue pas, ou qui ne rend pas un nombre, est
  refusée en nommant le bloc et le paramètre — sans quoi on chercherait
  longtemps d'où vient un résultat faux.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     K = 3;
     matlibre_sl_expression('2 * K', 'gain', 'Gain')      % 6

  Voir aussi SIM, ADD_BLOCK, SET_PARAM, EVALIN.
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

  Le contournement sert aussi quand la cible n'est pas devant la
  source, retour ou non : un bloc déplacé à la souris peut se retrouver
  derrière celui qui l'alimente, et une liaison directe reviendrait
  alors sur ses pas, la pointe de flèche pointant à l'envers.

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

## `matlibre_sl_geometrie`

```
MATLIBRE_SL_GEOMETRIE Où se place chaque bloc, et par où passe chaque lien.
  G = MATLIBRE_SL_GEOMETRIE(MODELE) rend une structure décrivant le
  schéma : pour chaque bloc son nom, son type, son étiquette, ses signes
  et son cadre ; pour chaque lien ses deux bouts, son port d'arrivée et
  s'il referme une boucle.

  C'est la géométrie que partagent les deux façons de montrer un
  schéma : OPEN_SYSTEM la trace dans une figure, l'éditeur du bureau la
  peint sur sa toile et s'en sert pour savoir où l'on a cliqué. Une
  seule mise en place, donc, et deux dessins qui s'accordent.

  Un bloc qui porte un paramètre POSITION garde la place qu'on lui a
  donnée — c'est ainsi qu'un schéma déplacé à la souris se retient.
  POSITION vaut [gauche haut droite bas], comme dans Simulink. Les
  autres sont placés par couches, de la source vers la sortie.

  Les champs rendus :
    G.blocs(k).nom, .type, .etiquette, .signes
    G.blocs(k).noms, .valeurs                  ses réglages, en texte
    G.blocs(k).gauche, .haut, .droite, .bas    le cadre du bloc
    G.blocs(k).pose                            vrai si POSITION le fixait
    G.liens(k).source, .cible, .port, .retour
    G.largeur, G.hauteur                       la taille d'un bloc par défaut

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('c');
     m = add_block(m, 'constant', 'u', 'Value', 1);
     m = add_block(m, 'gain', 'k', 'Gain', 2);
     m = add_line(m, 'u', 'k');
     g = matlibre_sl_geometrie(m);
     g.blocs(2).gauche > g.blocs(1).gauche      % le gain est a droite

  Voir aussi OPEN_SYSTEM, MATLIBRE_SL_DISPOSITION, MATLIBRE_SL_RANGS.
```

## `matlibre_sl_indice`

```
MATLIBRE_SL_INDICE Rang d'un bloc désigné par son nom.
  K = MATLIBRE_SL_INDICE(MODELE,NOM) rend le rang du bloc dans
  MODELE.blocs, et lève une erreur qui nomme le bloc s'il n'existe pas.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'gain', 'g', 'Gain', 2);
     matlibre_sl_indice(m, 'g')       % 1

  Voir aussi ADD_LINE, DELETE_BLOCK, GET_PARAM.
```

## `matlibre_sl_modele`

```
MATLIBRE_SL_MODELE Rend un modèle, qu'on l'ait donné par valeur ou par nom.
  MODELE = MATLIBRE_SL_MODELE(ENTREE) accepte un modèle bâti par
  NEW_SYSTEM, ou le nom d'une variable de l'espace de travail de base
  qui en porte un, ou le nom d'un modèle ouvert dans la session, ou le
  nom d'un fichier .m qui le rend.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('essai');
     nom = matlibre_sl_modele(m).nom;      % 'essai'

  Voir aussi LINMOD, TRIM, OPEN_SYSTEM, LOAD_SYSTEM, SIM.
```

## `matlibre_sl_ordre`

```
MATLIBRE_SL_ORDRE L'ordre dans lequel les blocs se calculent.
  [ORDRE,DIRECTE,MEMOIRE] = MATLIBRE_SL_ORDRE(MODELE) rend l'ordre de
  calcul des blocs, et pour chacun s'il transmet son entrée à l'instant
  même et s'il porte un état.

  Un bloc à transmission directe se calcule après ce qui l'alimente.
  Un bloc qui n'en a pas — intégrateur, retard, mémoire, et une
  représentation d'état dont D est nul — rend une valeur qui ne dépend
  que de son état : il peut donc être placé le premier, et c'est ce qui
  casse les boucles.

  C'est la même règle que celle de SIM. Elle est ici pour que le
  programme engendré par MATLIBRE_SL_PROGRAMME calcule dans le même
  ordre — sans quoi il rendrait d'autres nombres que la simulation.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('c');
     m = add_block(m, 'gain', 'k', 'Gain', 2);
     m = add_block(m, 'constant', 'u', 'Value', 1);
     m = add_line(m, 'u', 'k');
     matlibre_sl_ordre(m)             % [2 1] : la source avant le gain

  Voir aussi SIM, MATLIBRE_SL_PROGRAMME.
```

## `matlibre_sl_ouverts`

```
MATLIBRE_SL_OUVERTS Registre des modèles ouverts dans la session.
  Un modèle est ici une valeur, non une fenêtre. « Ouvert » veut donc
  dire « connu de la session » : OPEN_SYSTEM et LOAD_SYSTEM y
  inscrivent le modèle, CLOSE_SYSTEM et BDCLOSE l'en retirent, GCS rend
  le dernier inscrit, et BDISLOADED répond sur un nom.

  L'inscription retient aussi le numéro de la figure où le schéma est
  tracé, quand il y en a une, pour que CLOSE_SYSTEM sache laquelle
  fermer.

  Actions : 'inscrire', 'retirer', 'vider', 'lire', 'figure', 'connu',
  'noms', 'dernier'.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_sl_ouverts('vider');
     matlibre_sl_ouverts('inscrire', 'essai', new_system('essai'));
     matlibre_sl_ouverts('dernier')          % 'essai'
     matlibre_sl_ouverts('vider');

  Voir aussi OPEN_SYSTEM, CLOSE_SYSTEM, GCS, BDISLOADED, LOAD_SYSTEM.
```

## `matlibre_sl_pile`

```
MATLIBRE_SL_PILE Les états passés d'un modèle, pour défaire et refaire.
  MATLIBRE_SL_PILE('poser',MODELE) retient l'état courant du modèle
  avant qu'on le change.
  MODELE = MATLIBRE_SL_PILE('annuler',MODELE) rend l'état d'avant le
  dernier changement, et garde celui qu'on quitte pour pouvoir le
  refaire.
  MODELE = MATLIBRE_SL_PILE('refaire',MODELE) revient sur une annulation.
  MATLIBRE_SL_PILE('vider',MODELE) oublie tout d'un modèle.
  N = MATLIBRE_SL_PILE('profondeur',MODELE) dit combien d'annulations
  restent possibles, et 'refaisables' combien de rétablissements.

  Les états sont rangés par nom de modèle, et la pile vit aussi
  longtemps que la session. Un modèle est une valeur : en retenir une
  copie suffit, il n'y a pas de références à démêler.

  Poser un état efface ce qu'on pouvait refaire : c'est la règle de
  toute pile d'annulation, et l'ignorer laisserait rétablir un état qui
  n'a plus de suite.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB,
  dont l'annulation n'existe que dans l'éditeur.

  Exemple :
     m = add_block(new_system('essai'), 'gain', 'k', 'Gain', 1);
     matlibre_sl_pile('vider', m);
     matlibre_sl_pile('poser', m);
     m = set_param(m, 'k', 'Gain', 5);
     m = matlibre_sl_pile('annuler', m);
     get_param(m, 'k', 'Gain')                % 1 : le changement est defait

  Voir aussi SET_PARAM, ADD_BLOCK, DELETE_BLOCK, OPEN_SYSTEM.
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

## `matlibre_sl_programme`

```
MATLIBRE_SL_PROGRAMME Écrit le programme .m qui simule un schéma-bloc.
  TEXTE = MATLIBRE_SL_PROGRAMME(MODELE) rend le texte d'une fonction
  MATLAB qui calcule ce que calcule le schéma, sans passer par
  Simulink : des variables, une boucle, de l'arithmétique.
  MATLIBRE_SL_PROGRAMME(MODELE,NOM) choisit le nom de la fonction.

  Ce n'est pas SAVE_SYSTEM. SAVE_SYSTEM écrit le programme qui
  *rebâtit* le modèle — NEW_SYSTEM, ADD_BLOCK, ADD_LINE —, et
  LOAD_SYSTEM le relit : c'est l'aller-retour du schéma. Ici, on écrit
  le programme qui *fait ce que le schéma fait*, et il n'y a pas de
  retour : on ne remonte pas d'un calcul quelconque au schéma qui
  l'aurait produit.

  Le programme rendu ne dépend de rien : les réglages y sont inscrits
  tels qu'ils valent au moment où on l'écrit. Un gain réglé sur « K »
  y devient la valeur de K, non la lettre — sans quoi le programme
  demanderait un espace de travail qu'il n'a pas. C'est ce que fait
  aussi le générateur de code de MathWorks.

  L'ordre de calcul est celui de SIM, et l'intégration la même : le
  programme rend donc les mêmes nombres, au bit près. C'est ce que
  vérifie le test.

  Les blocs échantillonnés, le retard pur et les échanges avec l'espace
  de travail ne s'écrivent pas encore : ils sont refusés en les
  nommant, plutôt que passés sous silence.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB,
  dont le générateur de code écrit du C, non du MATLAB.

  Exemple :
     m = new_system('chute');
     m = add_block(m, 'constant', 'g', 'Value', -9.81);
     m = add_block(m, 'integrator', 'vitesse');
     m = add_line(m, 'g', 'vitesse');
     p = matlibre_sl_programme(m);
     ~isempty(strfind(p, 'function'))          % 1 : c'est une fonction

  Voir aussi SAVE_SYSTEM, LOAD_SYSTEM, SIM, MATLIBRE_SL_ORDRE.
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

## `matlibre_sl_remplacer`

```
MATLIBRE_SL_REMPLACER Repose un modèle sous le sous-système d'où il vient.
  MODELE = MATLIBRE_SL_REMPLACER(MODELE,CHEMIN,SOUS) rend MODELE où le
  sous-système que CHEMIN désigne porte à présent SOUS. Le chemin
  s'écrit « boite » pour un niveau, « boite/interne » pour deux ; un
  chemin vide rend SOUS lui-même.

  C'est le retour de MATLIBRE_SL_DEDANS. L'éditeur du bureau s'en sert
  quand on modifie un bloc à l'intérieur d'un sous-système : il
  descend, applique la modification, et repose le tout — en une seule
  commande, si bien qu'un CTRL+Z la défait d'un coup.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     interne = add_block(new_system('dedans'), 'gain', 'k', 'Gain', 3);
     m = add_block(new_system('dehors'), 'subsystem', 'boite', ...
                   'Model', interne);
     m = matlibre_sl_remplacer(m, 'boite', ...
                               set_param(interne, 'k', 'Gain', 5));
     get_param(matlibre_sl_dedans(m, 'boite'), 'k', 'Gain')     % 5

  Voir aussi MATLIBRE_SL_DEDANS, MATLIBRE_SL_APLATIR, SET_PARAM.
```

## `matlibre_sl_signes`

```
MATLIBRE_SL_SIGNES Signes d'un bloc de sommation.
  SIGNES = MATLIBRE_SL_SIGNES(BLOC) rend la chaîne des signes, « ++ »
  par défaut : une sommation sans signe déclaré additionne.

  C'est aussi par cette chaîne que le nombre d'entrées d'un bloc
  voyage jusqu'à la toile de l'éditeur, qui compte ses caractères. Un
  sous-système en rend donc autant qu'il abrège de blocs INPORT — sans
  quoi ses liaisons arriveraient toutes au même point.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_sl_signes(struct('parametres', struct('Signs', '+-')))

  Voir aussi MATLIBRE_SL_FORME, ADD_BLOCK.
```

## `matlibre_sl_toile`

```
MATLIBRE_SL_TOILE Taille de figure qui convient à un schéma.
  [L,H] = MATLIBRE_SL_TOILE(UX,UY) rend la largeur et la hauteur en
  pixels d'une figure où un schéma de UX sur UY unités se lise : assez
  grande pour qu'un nom de bloc tienne sous son bloc, assez petite pour
  tenir sur un écran.

  La toile garde les proportions du schéma. Sans cela, « axis equal »
  ajuste l'échelle au côté le plus contraint et laisse le reste en
  blanc : un schéma en long se retrouvait en bandeau au milieu d'une
  toile carrée, ses étiquettes serrées à l'illisible.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [l, h] = matlibre_sl_toile(20, 5);
     abs(l / h - 4) < 0.05            % la toile suit les proportions

  Voir aussi OPEN_SYSTEM, MATLIBRE_SL_DISPOSITION.
```

## `new_system`

```
NEW_SYSTEM Crée un modèle Simulink vide.
  MODELE = NEW_SYSTEM(NOM) rend un modèle sans bloc ni lien. On le
  remplit par ADD_BLOCK, on le câble par ADD_LINE, on le règle par
  SET_PARAM, on le regarde par OPEN_SYSTEM, et on le simule par SIM.

  Le modèle est une structure à quatre champs : NOM, BLOCS, LIENS et
  PARAMETRES. C'est une valeur, non une référence : chaque fonction en
  rend une nouvelle et laisse l'ancienne intacte.

  PARAMETRES porte les réglages du modèle lui-même — StopTime,
  FixedStep —, que SIM emploie quand on ne lui donne ni durée ni pas.
  ADD_PARAM les pose, DELETE_PARAM les retire.

  Les modèles se décrivent ici en appelant ces fonctions ; les fichiers
  .slx de MathWorks, dont le format n'est pas public, ne se lisent pas.
  SAVE_SYSTEM en écrit un programme .m, que LOAD_SYSTEM relit.

  Exemple :
     m = new_system('rampe');
     m = add_block(m, 'constant', 'un', 'Value', 2);
     m = add_block(m, 'integrator', 'integ', 'InitialCondition', 0);
     m = add_line(m, 'un', 'integ');
     r = sim(m, 5, 0.001);

  Voir aussi ADD_BLOCK, ADD_LINE, SET_PARAM, ADD_PARAM, SIM, OPEN_SYSTEM.
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

  Le modèle est inscrit au registre de la session : GCS le nomme,
  BDISLOADED répond vrai, et CLOSE_SYSTEM le ferme avec sa figure.
  OPEN_SYSTEM(NOM) rouvre un modèle déjà inscrit, ou exécute le
  fichier NOM.m qui le rend.

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
     close_system(m);

  Voir aussi NEW_SYSTEM, ADD_BLOCK, ADD_LINE, CLOSE_SYSTEM, GCS, SIM.
```

## `replace_block`

```
REPLACE_BLOCK Remplace les blocs d'un type par un autre type.
  MODELE = REPLACE_BLOCK(MODELE,ANCIEN,NOUVEAU) change le type de tous
  les blocs de type ANCIEN en NOUVEAU. Les noms, les liens et les
  paramètres sont conservés.
  REPLACE_BLOCK(MODELE,ANCIEN,NOUVEAU,'Param',VALEUR,...) fixe en outre
  des paramètres sur chaque bloc remplacé.

  Le câblage ne bouge pas : c'est tout l'intérêt, remplacer un
  intégrateur continu par son équivalent discret sans redessiner le
  schéma.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'integrator', 'i1');
     m = add_block(m, 'integrator', 'i2');
     m = replace_block(m, 'integrator', 'discreteintegrator', ...
                       'SampleTime', 0.1);
     get_param(m, 'i1', 'BlockType')          % 'discreteintegrator'
     get_param(m, 'i2', 'SampleTime')         % 0.1

  Voir aussi ADD_BLOCK, DELETE_BLOCK, SET_PARAM, FIND_SYSTEM.
```

## `save_system`

```
SAVE_SYSTEM Enregistre un modèle dans un fichier .m qui le rebâtit.
  SAVE_SYSTEM(MODELE) écrit MODELE.nom.m dans le dossier courant.
  SAVE_SYSTEM(MODELE,FICHIER) choisit le nom du fichier ; l'extension
  .m est ajoutée si elle manque. La fonction rend le chemin écrit.

  Le fichier produit est un programme : une fonction sans argument qui
  appelle NEW_SYSTEM, ADD_BLOCK et ADD_LINE, et rend le modèle.
  LOAD_SYSTEM le relit, et SIM l'accepte par son nom. C'est un format
  qui se lit, se compare et se range dans un dépôt — ce que le .slx de
  MathWorks, binaire et non documenté, ne permet pas.

  Les valeurs de paramètres sont réécrites par MAT2STR pour les
  nombres et entre apostrophes pour le texte : ce qu'on relit est ce
  qu'on avait, à la représentation près.

  Un sous-système porte tout un modèle en paramètre. Le fichier le
  bâtit d'abord, dans sa propre variable, puis le donne au bloc qui
  l'abrège : un schéma emboîté se relit donc comme un schéma plat.

  Exemple :
     m = new_system('boucle');
     m = add_block(m, 'constant', 'c', 'Value', 2);
     m = add_block(m, 'gain', 'g', 'Gain', 3);
     m = add_line(m, 'c', 'g');
     chemin = save_system(m, [tempname() '.m']);
     relu = load_system(chemin);
     get_param(relu, 'g', 'Gain')             % 3
     delete(chemin);

  Voir aussi LOAD_SYSTEM, NEW_SYSTEM, ADD_BLOCK, ADD_LINE, CLOSE_SYSTEM.
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

  'Name' fait exception : il renomme le bloc, comme dans Simulink, au
  lieu de poser un réglage de ce nom. Les liens désignent les blocs par
  leur rang, si bien que le câblage ne bouge pas.

  MODELE = SET_PARAM(MODELE,'Nom',VALEUR) — une seule valeur, sans nom
  de bloc devant — change un réglage du modèle lui-même, comme
  StopTime ou FixedStep. La forme se distingue sans ambiguïté : un
  réglage de bloc se donne toujours par couples, donc en nombre pair
  d'arguments après le nom du bloc.

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
     m = set_param(m, 'gain', 'Name', 'correcteur');
     get_param(m, 'correcteur', 'Gain')       % 5 : le bloc a change de nom

  Voir aussi ADD_BLOCK, ADD_PARAM, NEW_SYSTEM, SIM.
```

## `sim`

```
SIM Simule un modèle à pas fixe.
  RESULTAT = SIM(MODELE,TFINAL,PAS) rend une structure contenant le
  vecteur des instants et, pour chaque bloc, le signal relevé à sa
  sortie.
  SIM(MODELE,INSTANTS) accepte aussi un vecteur d'instants réguliers :
  il donne alors à la fois l'instant final et le pas.

  L'intégration se fait par défaut par la méthode d'Euler explicite.
  SIM(MODELE,TFINAL,SIMSET('Solver','ode4')) en choisit une autre :
  ode1 (Euler), ode2 (Heun), ode3 (Bogacki-Shampine) et ode4
  (Runge-Kutta d'ordre quatre) sont à pas fixe, et l'erreur d'un
  solveur d'ordre p décroît comme le pas à la puissance p. Un solveur
  d'ordre supérieur évalue la dérivée en des points intermédiaires du
  pas : cela n'a de sens que pour un état continu — intégrateur,
  représentation d'état, fonction de transfert, PID —, et un modèle
  qui porte un retard ou un bloc échantillonné est refusé en nommant
  le bloc. Le modèle peut porter son solveur lui-même, par
  ADD_PARAM(M,'Solver','ode4').

  Les blocs sont évalués dans l'ordre d'un tri topologique, ce qui garantit
  qu'une entrée est calculée avant la sortie qui l'utilise. Seuls les
  blocs sans transmission directe — intégrateur, retard, mémoire,
  retard pur, tenue d'ordre zéro, et les représentations d'état dont D
  est nul — coupent la remontée, et cassent donc les boucles
  algébriques. Un bloc à mémoire mais à transmission directe, comme le
  dérivateur ou le relais, ne la coupe pas : sa sortie dépend de son
  entrée à l'instant même.

  Tous les paramètres sont résolus avant la boucle : à l'intérieur, il
  ne reste que de l'arithmétique. Un paramètre numérique donné entre
  apostrophes est une expression, évaluée à ce moment-là dans l'espace
  de travail de base : changer la variable et relancer SIM change le
  résultat sans que le modèle ait bougé. Les blocs « toworkspace » et
  « fromworkspace » font l'échange dans les deux sens.

  Un bloc « subsystem » porte tout un modèle : SIM le déplie avant de
  simuler, et rend exactement ce que rendrait le schéma écrit à plat.
  Le relevé porte alors les blocs intérieurs sous le nom
  « sousSysteme/bloc », et le sous-système lui-même porte la valeur de
  sa sortie.

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

  Voir aussi NEW_SYSTEM, ADD_BLOCK, ADD_LINE, SIMPLOT, LINMOD.
```

## `simget`

```
SIMGET Lit une option de simulation.
  V = SIMGET(OPTIONS,'Nom') rend la valeur de l'option, et une matrice
  vide si elle n'est pas réglée. SIMGET(OPTIONS) rend la structure
  entière.

  Exemple :
     o = simset('FixedStep', 0.02);
     simget(o, 'FixedStep')           % 0.02
     isempty(simget(simset(), 'FixedStep'))   % vrai : rien n'est regle

  Voir aussi SIMSET, SIM.
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

## `simset`

```
SIMSET Rassemble les options d'une simulation.
  OPTIONS = SIMSET('Nom',VALEUR,...) rend une structure d'options que
  SIM accepte à la place du pas : SIM(MODELE,TFINAL,OPTIONS).
  OPTIONS = SIMSET(ANCIENNES,'Nom',VALEUR,...) part d'un jeu existant.
  SIMSET() sans argument rend le jeu par défaut.

  Options lues :
    FixedStep       le pas d'intégration
    Solver          le nom du solveur, à pas fixe : 'ode1' (Euler
                    explicite, celui par défaut), 'ode2' (Heun),
                    'ode3' (Bogacki-Shampine), 'ode4' (Runge-Kutta
                    d'ordre quatre), ou 'FixedStepDiscrete', qui vaut
                    ode1. Tout autre nom est refusé plutôt qu'ignoré.

  Un solveur d'ordre supérieur évalue la dérivée en des points
  intermédiaires du pas : cela n'a de sens que pour un état continu.
  Un modèle qui porte un retard ou un bloc échantillonné est refusé
  par SIM en nommant le bloc, plutôt qu'intégré de travers.

  Les options que MATLAB accepte et que MatLibre ne sait pas honorer
  sont refusées en le disant : une option acceptée sans effet ferait
  croire à un réglage qui n'a pas lieu.

  Exemple :
     o = simset('FixedStep', 0.05);
     m = new_system('essai');
     m = add_block(m, 'constant', 'c', 'Value', 1);
     r = sim(m, 1, o);
     numel(r.temps)                   % 21

  Voir aussi SIMGET, SIM, ADD_PARAM.
```

## `trim`

```
TRIM Cherche un point d'équilibre d'un modèle.
  [X,U,Y,DX] = TRIM(MODELE) cherche l'état et l'entrée qui annulent
  toutes les dérivées, en partant de zéro.
  TRIM(MODELE,X0,U0,Y0) part des valeurs données et vise la sortie Y0.
  TRIM(MODELE,X0,U0,Y0,IX,IU,IY) tient fixées les composantes désignées
  par IX dans l'état et IU dans l'entrée, et n'impose la sortie que sur
  les composantes IY.

  La recherche est un Gauss-Newton amorti sur le résidu formé des
  dérivées d'état et des écarts de sortie imposés. Le jacobien vient de
  différences centrées, comme dans LINMOD : sur un modèle linéaire,
  l'équilibre est donc atteint en une itération, à l'arrondi près.

  DX est rendu pour qu'on puisse juger : un équilibre trouvé se
  reconnaît à ce que DX y est nul, non à ce que la fonction a rendu
  sans erreur. Quand la recherche n'y parvient pas, l'avertissement le
  dit et le meilleur point trouvé est rendu quand même.

  Exemple :
     m = new_system('premier');
     m = add_block(m, 'inport', 'u', 'Port', 1);
     m = add_block(m, 'sum', 's', 'Signs', '+-');
     m = add_block(m, 'integrator', 'x');
     m = add_block(m, 'outport', 'y', 'Port', 1);
     m = add_line(m, 'u', 's', 1);
     m = add_line(m, 'x', 's', 2);
     m = add_line(m, 's', 'x');
     m = add_line(m, 'x', 'y');
     [xe, ue, ye, dxe] = trim(m, 0, 1, [], [], 1, []);
     abs(xe - 1) < 1e-8                   % l'equilibre de x' = u - x

  Voir aussi LINMOD, DLINMOD, SIM, FSOLVE.
```

