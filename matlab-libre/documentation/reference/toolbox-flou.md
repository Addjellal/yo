# Toolbox `flou`

```
% Fuzzy Logic Toolbox — logique floue.
%
% Fonctions d'appartenance
%   trimf, trapmf     - Triangle et trapèze
%   gaussmf, gauss2mf - Gaussienne, et gaussienne à plateau
%   gbellmf           - Cloche généralisée
%   sigmf, dsigmf, psigmf - Sigmoïde, différence et produit
%   zmf, smf, pimf    - Courbes en Z, en S et en Pi
%   linsmf, linzmf    - Les mêmes, à coudes nets
%   evalmf            - Évaluation par le nom du type
%   plotmf            - Tracé des modalités d'une variable
%
% Construction d'un système
%   newfis            - Système vide, Mamdani ou Sugeno
%   mamfis, sugfis    - Les deux mêmes, forme moderne
%   addvar, addmf, addrule - Variables, modalités, règles
%   addInput, addOutput - Variable et partition régulière en un appel
%   addMF, addRule    - Modalité par nom, règles écrites en clair
%   rmvar, rmmf       - Retraits, avec mise à jour des règles
%   removeInput, removeOutput - Les mêmes, par nom
%   removeMF, removeRule - Retrait d'une modalité, d'une règle
%   convertToSugeno   - Traduction d'un Mamdani en Sugeno
%   getfis, setfis    - Lecture et écriture des champs
%   readfis, writefis - Fichiers .fis
%   showrule, plotfis - Règles en clair, structure du système
%
% Inférence
%   evalfis           - Mamdani et Sugeno, plusieurs sorties, cinq opérateurs
%   defuzz            - Défuzzification : centroid, bisector, mom, som, lom
%   probor            - Ou probabiliste
%   gensurf           - Surface de réponse
%   evalfisOptions, gensurfOptions - Réglages de l'inférence et du tracé
%   fuzarith          - Arithmétique sur les nombres flous
%
% Classification et apprentissage
%   fcm               - C-moyennes floues
%   subclust          - Classification soustractive de Chiu
%   genfis1           - Système par partition régulière
%   genfis2           - Système par classification soustractive
%   genfis3           - Système par c-moyennes floues
%   genfis            - Interface commune aux trois
%   anfis             - Apprentissage hybride de Jang
%   findcluster       - Classification et tracé du nuage
%   tunefis           - Réglage des paramètres sur des données
%   getTunableSettings, getTunableValues, setTunableValues
%                     - Ce qu'un réglage peut toucher, et sa valeur
%   anfisOptions, genfisOptions, subclustOptions, fcmOptions,
%   tunefisOptions    - Réglages de l'apprentissage
%   getFISCodeGenerationData - Le système sous forme purement numérique
```

## `addInput`

```
ADDINPUT Ajoute une variable d'entrée à un système flou.
  FIS = ADDINPUT(FIS) ajoute une entrée nommée « inputN », d'intervalle
  [0 1].
  FIS = ADDINPUT(FIS,[MIN MAX]) donne son intervalle.
  FIS = ADDINPUT(FIS,...,'Name',NOM) la nomme, 'NumMFs',N lui pose N
  modalités régulièrement réparties, 'MFType',T en choisit la forme
  ('trimf' par défaut, 'trapmf' et 'gaussmf' acceptées).

  C'est l'écriture moderne d'ADDVAR ; les deux mènent au même système.

  Exemple :
     fis = mamfis('Name', 'exemple');
     fis = addInput(fis, [0 10], 'Name', 'service', 'NumMFs', 3);
     numel(fis.entrees{1}.mf)       % 3

  Voir aussi ADDOUTPUT, ADDMF, ADDRULE, REMOVEINPUT, ADDVAR.
```

## `addMF`

```
ADDMF Ajoute une modalité à une variable, par son nom.
  FIS = ADDMF(FIS,NOM,TYPE,PARAMS) ajoute à la variable nommée NOM —
  entrée ou sortie — une fonction d'appartenance de forme TYPE.
  FIS = ADDMF(...,'Name',N) la nomme ; sans cela elle s'appelle « mfK ».

  C'est l'écriture moderne d'ADDMF à quatre arguments, qui désignait la
  variable par son genre et son rang. Les deux formes coexistent : si
  le deuxième argument est 'input' ou 'output', c'est l'ancienne.

  Exemple :
     fis = addInput(mamfis, [0 10], 'Name', 'service');
     fis = addMF(fis, 'service', 'trimf', [0 0 5], 'Name', 'faible');
     fis.entrees{1}.mf{1}.nom       % 'faible'

  Voir aussi ADDINPUT, ADDOUTPUT, ADDRULE, REMOVEMF, EVALMF.
```

## `addOutput`

```
ADDOUTPUT Ajoute une variable de sortie à un système flou.
  FIS = ADDOUTPUT(FIS,[MIN MAX]) ajoute une sortie nommée « outputN ».
  Les options sont celles d'ADDINPUT : 'Name', 'NumMFs', 'MFType'.

  Exemple :
     fis = mamfis('Name', 'exemple');
     fis = addOutput(fis, [0 30], 'Name', 'pourboire', 'NumMFs', 3);

  Voir aussi ADDINPUT, ADDMF, ADDRULE, REMOVEOUTPUT, ADDVAR.
```

## `addRule`

```
ADDRULE Ajoute des règles à un système flou.
  FIS = ADDRULE(FIS,R) où R est une matrice, une ligne par règle :
  [mfEntree1 ... mfEntreeN mfSortie1 ... mfSortieM POIDS OPERATEUR],
  l'opérateur valant 1 pour « et » et 2 pour « ou ». Un zéro en place
  d'une modalité veut dire « peu importe ».

  FIS = ADDRULE(FIS,TEXTE) accepte aussi les règles écrites, une par
  ligne d'un tableau de cellules :

     "si service est faible alors pourboire est petit"

  Les mots reconnus sont « si »/'if', « et »/'and', « ou »/'or',
  « alors »/'then', « est »/'is' et « non »/'not'.

  Exemple :
     fis = addInput(mamfis, [0 10], 'Name', 'service', 'NumMFs', 2);
     fis = addOutput(fis, [0 30], 'Name', 'pourboire', 'NumMFs', 2);
     fis = addRule(fis, {'si service est mf1 alors pourboire est mf1', ...
                         'si service est mf2 alors pourboire est mf2'});
     size(fis.regles, 1)            % 2

  Voir aussi ADDRULE, SHOWRULE, EVALFIS, ADDINPUT.
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

## `ajouterVariable`

```
AJOUTERVARIABLE Rouage commun d'ADDINPUT et d'ADDOUTPUT.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `anfis`

```
ANFIS Apprentissage d'un système de Sugeno par méthode hybride.
  FIS = ANFIS(DONNEES) apprend un système à partir d'une matrice dont
  les premières colonnes sont les entrées et la dernière la sortie.
  FIS = ANFIS(DONNEES,FIS0) part d'un système donné, construit par
  GENFIS1 ou GENFIS2.
  FIS = ANFIS(DONNEES,FIS0,N) fixe le nombre d'époques, dix par défaut.
  [FIS,ERREURS] = ANFIS(...) rend l'erreur quadratique moyenne à chaque
  époque.

  L'apprentissage est celui de Jang : à chaque époque, les paramètres
  de conclusion sont trouvés exactement par moindres carrés — la sortie
  en dépend linéairement —, puis les paramètres de prémisse sont
  corrigés par descente de gradient. Le pas s'adapte : il croît de dix
  pour cent quand l'erreur baisse, et se réduit de moitié sinon.

  C'est cette séparation qui fait la force de la méthode : la moitié
  linéaire du problème est résolue d'un coup au lieu d'être approchée.

  Exemple :
     x = (0:0.05:10)';
     donnees = [x, sin(x)];
     [fis, e] = anfis(donnees, genfis1(donnees, 7), 20);
     e(end) < e(1)   % vrai

  Voir aussi GENFIS1, GENFIS2, EVALFIS, FCM.
```

## `anfisOptions`

```
ANFISOPTIONS Options d'apprentissage d'ANFIS.
  O = ANFISOPTIONS rend les réglages par défaut :
    InitialFIS              système de départ, ou nombre de modalités
                            par entrée si l'on donne un nombre
    EpochNumber             nombre d'époques, 10
    InitialStepSize         pas initial, 0,01
    StepSizeDecreaseRate    facteur de réduction du pas, 0,9
    StepSizeIncreaseRate    facteur d'augmentation, 1,1
    ErrorGoal               erreur en deçà de laquelle on s'arrête, 0
    DisplayANFISInformation, DisplayErrorValues, DisplayStepSize,
    DisplayFinalResults     affichages, tous à 1 dans MATLAB

  Exemple :
     o = anfisOptions('EpochNumber', 40, 'InitialStepSize', 0.05);
     fis = anfis([x, y], o);

  Voir aussi ANFIS, GENFISOPTIONS, TUNEFISOPTIONS.
```

## `convertToSugeno`

```
CONVERTTOSUGENO Traduit un système de Mamdani en système de Sugeno.
  SUG = CONVERTTOSUGENO(FIS) rend un système équivalent dont chaque
  modalité de sortie devient une constante : celle qu'on obtient en
  défuzzifiant la modalité seule, par la méthode du système d'origine.

  La traduction est fidèle règle par règle, non point par point : la
  sortie diffère de celle du Mamdani, l'agrégation des ensembles flous
  n'étant pas la même chose que la moyenne pondérée de leurs centres.
  Ce qu'on y gagne est la vitesse, et la possibilité d'employer ANFIS.

  Un système déjà de Sugeno est rendu tel quel.

  Exemple :
     fis = addInput(mamfis, [0 10], 'Name', 'a', 'NumMFs', 2);
     fis = addOutput(fis, [0 1], 'Name', 'b', 'NumMFs', 2);
     fis = addRule(fis, [1 1 1 1; 2 2 1 1]);
     sug = convertToSugeno(fis);
     sug.type                       % 'sugeno'

  Voir aussi MAMFIS, SUGFIS, EVALFIS, GENFIS.
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

## `estEntree`

```
ESTENTREE Le mot-clé désigne-t-il une entrée ?
  Accepte 'input' et 'in' pour une entrée, 'output' et 'out' pour une
  sortie ; toute autre valeur est refusée.
```

## `evalfis`

```
EVALFIS Inférence floue, Mamdani ou Sugeno.
  Y = EVALFIS(FIS,X) évalue le système. X est un vecteur d'entrées, ou
  une matrice dont chaque ligne est un jeu d'entrées ; Y a alors une
  ligne par jeu et une colonne par sortie.

  L'ordre inverse, EVALFIS(X,FIS), est celui de l'ancienne interface :
  il reste accepté, le système se reconnaissant à ce qu'il est une
  structure.

  Y = EVALFIS(X,FIS,N) fixe le nombre de points de la grille de
  défuzzification, 101 par défaut.

  [Y,FORCES,AGREGATS,SORTIESREGLES] = EVALFIS(...) rend en plus, pour la
  dernière ligne d'entrées, les forces d'activation des règles, les
  ensembles flous agrégés par sortie, et la contribution de chaque règle.

  L'inférence suit les cinq opérateurs du système : conjonction,
  disjonction, implication, agrégation et défuzzification. Un indice de
  fonction d'appartenance négatif dans une règle vaut négation, un
  indice nul vaut « peu importe ».

  Chez Sugeno, les conclusions sont des fonctions des entrées :
  'constant' de paramètre c, ou 'linear' de paramètres [a1 ... aN a0].
  La sortie est leur moyenne pondérée par les forces ('wtaver') ou leur
  somme pondérée ('wtsum').

  Exemple :
     fis = newfis('t');
     fis = addvar(fis, 'input', 'x', [0 10]);
     fis = addmf(fis, 'input', 1, 'bas', 'trimf', [0 0 5]);
     fis = addmf(fis, 'input', 1, 'haut', 'trimf', [5 10 10]);
     fis = addvar(fis, 'output', 'y', [0 1]);
     fis = addmf(fis, 'output', 1, 'petit', 'trimf', [0 0 0.5]);
     fis = addmf(fis, 'output', 1, 'grand', 'trimf', [0.5 1 1]);
     fis = addrule(fis, [1 1 1 1; 2 2 1 1]);
     evalfis(fis, 5)

  Voir aussi NEWFIS, ADDRULE, DEFUZZ, GENSURF.
```

## `evalfisOptions`

```
EVALFISOPTIONS Options d'une inférence floue.
  O = EVALFISOPTIONS rend les réglages par défaut d'EVALFIS :
    NumSamplePoints        points de la grille de défuzzification, 101
    OutOfRangeInputValueMessage  ce qu'on fait d'une entrée hors
                           intervalle : 'warning' (défaut), 'error' ou
                           'none'
    NoRuleFiredMessage     ce qu'on fait quand aucune règle ne
                           s'applique
    EmptyOutputFuzzySetMessage  de même pour un ensemble de sortie vide

  Exemple :
     o = evalfisOptions('NumSamplePoints', 501);
     y = evalfis(fis, 5, o);

  Voir aussi EVALFIS, GENSURFOPTIONS, DEFUZZ.
```

## `evalmf`

```
EVALMF Évalue une fonction d'appartenance par son nom.
  Y = EVALMF(X,TYPE,PARAMS) où TYPE vaut 'trimf', 'trapmf', 'gaussmf',
  'gauss2mf', 'gbellmf', 'sigmf', 'dsigmf', 'psigmf', 'zmf', 'smf',
  'pimf', 'linsmf', 'linzmf', ou, pour une sortie de Sugeno,
  'constant' ou 'linear'.

  Exemple :
     evalmf(0:4, 'trimf', [0 2 4])   % [0 0.5 1 0.5 0]

  Voir aussi TRIMF, TRAPMF, GAUSSMF, EVALFIS.
```

## `fcm`

```
FCM Classification par c-moyennes floues.
  [C,U,J] = FCM(DONNEES,N) partage les lignes de DONNEES en N classes
  floues. C porte les centres, une ligne par classe ; U(i,j) est le
  degré d'appartenance du point j à la classe i, les colonnes sommant à
  un ; J retrace la valeur du critère à chaque itération.

  FCM(DONNEES,N,OPTIONS) où OPTIONS vaut
    [EXPOSANT MAXITER TOLERANCE AFFICHAGE]
  valant par défaut [2 100 1e-5 0]. L'exposant, souvent noté m, règle le
  flou : à m proche de un la partition devient nette, et plus m grandit
  plus les appartenances s'égalisent.

  Le critère minimisé est somme_i somme_j U(i,j)^m ||x_j - c_i||^2. À
  chaque tour, les centres sont les barycentres pondérés des points, et
  les appartenances l'inverse des distances élevées à la puissance
  2/(m-1), normalisé : c'est le point fixe des conditions d'optimalité.

  Exemple :
     donnees = [randn(50,2); randn(50,2) + 6];
     [c, u] = fcm(donnees, 2);

  Voir aussi SUBCLUST, GENFIS2, EVALFIS.
```

## `fcmOptions`

```
FCMOPTIONS Options des c-moyennes floues.
  O = FCMOPTIONS rend les réglages par défaut de FCM :
    NumClusters      nombre de classes, 'auto'
    Exponent         exposant de flou, 2
    MaxNumIteration  nombre maximal d'itérations, 100
    MinImprovement   amélioration en deçà de laquelle on s'arrête, 1e-5
    DistanceMetric   distance employée, 'euclidean'
    Verbose          affichage, 0

  Exemple :
     o = fcmOptions('NumClusters', 3, 'Exponent', 1.5);
     [c, u] = fcm(donnees, o);

  Voir aussi FCM, SUBCLUSTOPTIONS, GENFISOPTIONS.
```

## `findcluster`

```
FINDCLUSTER Classification floue d'un jeu de données.
  [C,U] = FINDCLUSTER(X,N) partage les lignes de X en N classes par les
  c-moyennes floues, et rend les centres et les appartenances.
  [C,U] = FINDCLUSTER(X,RA,'subtractive') emploie la classification
  soustractive de Chiu, RA étant le rayon d'influence : le nombre de
  classes sort alors du calcul.

  FINDCLUSTER(...) sans sortie demandée trace le nuage et ses centres.

  MATLAB ouvre ici une application où l'on charge un fichier et déplace
  des curseurs. MatLibre n'a pas d'application interactive : il fait le
  calcul et montre le résultat.

  Exemple :
     nuage = [randn(40, 2); randn(40, 2) + 6];
     c = findcluster(nuage, 2);
     size(c, 1)                     % 2

  Voir aussi FCM, SUBCLUST, GENFIS, FCMOPTIONS.
```

## `fuzarith`

```
FUZARITH Arithmétique sur les nombres flous.
  Y = FUZARITH(X,A,B,OPERATION) où A et B sont deux ensembles flous
  échantillonnés sur la grille X, et OPERATION vaut 'sum', 'sub',
  'prod' ou 'div'.

  Le calcul suit le principe d'extension, appliqué par coupes de
  niveau : à chaque niveau alpha, A et B se réduisent à deux
  intervalles, sur lesquels l'opération est celle de l'arithmétique
  d'intervalles. Le résultat est reconstitué en superposant les coupes.

  Exemple :
     x = linspace(-10, 30, 401);
     a = trimf(x, [1 2 3]);
     b = trimf(x, [4 6 8]);
     y = fuzarith(x, a, b, 'sum');
     x(find(y == max(y), 1))   % voisin de 8 : 2 + 6

  Voir aussi TRIMF, EVALMF, DEFUZZ.
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

## `genfis`

```
GENFIS Construction d'un système flou à partir de données.
  FIS = GENFIS(X,Y) partitionne régulièrement l'espace d'entrée, comme
  GENFIS1, et rend un système de Sugeno prêt pour ANFIS.
  FIS = GENFIS(X,Y,OPTIONS) où OPTIONS est une structure aux champs
    Methode          'gridpartition', 'subtractiveclustering' ou 'fcm'
    NumMembershipFunctions   pour la partition régulière
    ClusterInfluenceRange    pour la classification soustractive
    NumClusters              pour les c-moyennes floues

  Exemple :
     x = (0:0.1:10)';
     fis = genfis(x, sin(x), struct('Methode', 'fcm', 'NumClusters', 6));

  Voir aussi GENFIS1, GENFIS2, GENFIS3, ANFIS.
```

## `genfis1`

```
GENFIS1 Système de Sugeno par partition régulière de l'espace d'entrée.
  FIS = GENFIS1(DONNEES) construit un système à partir d'une matrice
  dont les dernières colonnes sont la sortie et les précédentes les
  entrées. Chaque entrée reçoit deux fonctions d'appartenance
  gaussiennes réparties uniformément sur son étendue, et il y a une
  règle par combinaison.

  FIS = GENFIS1(DONNEES,N) donne N fonctions par entrée, ou un vecteur
  d'autant d'éléments qu'il y a d'entrées.
  FIS = GENFIS1(DONNEES,N,TYPEENTREE,TYPESORTIE) choisit les types :
  'gaussmf' par défaut à l'entrée, 'linear' à la sortie ('constant'
  étant l'autre possibilité).

  Le système obtenu ne sait rien encore : ses conclusions sont nulles.
  C'est le point de départ d'ANFIS, qui les ajustera.

  Le nombre de règles croît comme N puissance le nombre d'entrées :
  au-delà de trois ou quatre entrées, GENFIS2 est préférable.

  Exemple :
     donnees = [(0:0.1:10)', sin(0:0.1:10)'];
     fis = genfis1(donnees, 5);
     numel(fis.regles(:,1))   % 5

  Voir aussi GENFIS2, ANFIS, EVALFIS.
```

## `genfis2`

```
GENFIS2 Système de Sugeno par classification soustractive.
  FIS = GENFIS2(X,Y,RA) cherche les centres de classes dans l'espace
  commun des entrées et des sorties, puis fait de chaque centre une
  règle : les prémisses sont des gaussiennes centrées sur la projection
  du centre dans l'espace d'entrée, et la conclusion la projection dans
  l'espace de sortie.

  À la différence de GENFIS1, le nombre de règles ne croît pas
  exponentiellement avec le nombre d'entrées : il vaut le nombre de
  classes trouvées, que le rayon RA règle indirectement.

  FIS = GENFIS2(X,Y,RA,BORNES,OPTIONS) passe les mêmes arguments que
  SUBCLUST.

  Exemple :
     x = (0:0.1:10)';
     fis = genfis2(x, sin(x), 0.3);

  Voir aussi GENFIS1, SUBCLUST, ANFIS.
```

## `genfis3`

```
GENFIS3 Système flou par c-moyennes floues.
  FIS = GENFIS3(X,Y) partage l'espace en deux classes par FCM et en tire
  un système de Sugeno, une règle par classe.
  FIS = GENFIS3(X,Y,TYPE,N) choisit le type, 'sugeno' ou 'mamdani', et
  le nombre de classes. N vaut 'auto' pour laisser FCM choisir deux
  classes par défaut.
  FIS = GENFIS3(X,Y,TYPE,N,OPTIONS) passe les options de FCM.

  À la différence de GENFIS2, le nombre de règles est demandé plutôt que
  déduit d'un rayon.

  Exemple :
     x = (0:0.1:10)';
     fis = genfis3(x, sin(x), 'sugeno', 6);

  Voir aussi GENFIS1, GENFIS2, FCM.
```

## `genfisOptions`

```
GENFISOPTIONS Options de construction d'un système à partir de données.
  O = GENFISOPTIONS(METHODE) où METHODE vaut 'GridPartition' (défaut),
  'SubtractiveClustering' ou 'FCMClustering'. Les champs dépendent de
  la méthode :
    GridPartition          NumMembershipFunctions, InputMembershipFunctionType
    SubtractiveClustering  ClusterInfluenceRange, SquashFactor,
                           AcceptRatio, RejectRatio
    FCMClustering          NumClusters, Exponent, MaxNumIteration,
                           MinImprovement

  Exemple :
     o = genfisOptions('FCMClustering', 'NumClusters', 4);
     fis = genfis(x, y, o);

  Voir aussi GENFIS, ANFISOPTIONS, SUBCLUSTOPTIONS, FCM.
```

## `gensurf`

```
GENSURF Surface de réponse d'un système flou.
  GENSURF(FIS) trace la sortie du système sur une grille de ses deux
  premières entrées ; les autres restent au milieu de leur intervalle.
  Un système à une seule entrée donne une courbe.

  GENSURF(FIS,[I J]) choisit les deux entrées, GENSURF(FIS,[I J],K) la
  sortie, GENSURF(FIS,[I J],K,N) le nombre de points de la grille
  (quinze par défaut).

  [X,Y,Z] = GENSURF(...) rend la grille et la surface au lieu de les
  tracer.

  La surface est ce qu'on regarde pour juger un système : elle montre
  d'un coup les paliers, les sauts et les zones où aucune règle ne
  s'applique.

  Exemple :
     fis = addInput(mamfis, [0 10], 'Name', 'a', 'NumMFs', 2);
     fis = addInput(fis, [0 10], 'Name', 'b', 'NumMFs', 2);
     fis = addOutput(fis, [0 1], 'Name', 'c', 'NumMFs', 2);
     fis = addRule(fis, [1 1 1 1 1; 2 2 2 1 1]);
     [x, y, z] = gensurf(fis);
     size(z)                        % 15x15

  Voir aussi EVALFIS, PLOTFIS, PLOTMF, GENSURFOPTIONS.
```

## `gensurfOptions`

```
GENSURFOPTIONS Options d'une surface de réponse.
  O = GENSURFOPTIONS rend les réglages par défaut de GENSURF :
    InputIndex     les deux entrées balayées, [1 2]
    OutputIndex    la sortie tracée, 1
    NumGridPoints  la finesse de la grille, 15
    ReferenceInputs  les valeurs des entrées qu'on ne balaie pas ;
                   vide veut dire « le milieu de leur intervalle »

  O = GENSURFOPTIONS('NumGridPoints',N,...) en change.

  Exemple :
     o = gensurfOptions('NumGridPoints', 31);
     [x, y, z] = gensurf(fis, o);

  Voir aussi GENSURF, EVALFIS, EVALFISOPTIONS.
```

## `getFISCodeGenerationData`

```
GETFISCODEGENERATIONDATA Système flou sous forme de données brutes.
  D = GETFISCODEGENERATIONDATA(FIS) rend le système sous une forme
  entièrement numérique — matrices d'intervalles, de types et de
  paramètres —, sans cellule ni structure imbriquée. C'est ce que le
  code engendré manipule, un générateur ne sachant pas suivre un arbre
  de cellules.

  D porte les champs : type, nEntrees, nSorties, intervallesEntrees,
  intervallesSorties, typesEntrees, typesSorties, parametresEntrees,
  parametresSorties, nombreModalites, regles et operateurs.

  Les paramètres sont rangés en matrice, une ligne par modalité,
  complétée de NaN quand les formes n'ont pas le même nombre de
  paramètres.

  Exemple :
     fis = addInput(mamfis, [0 10], 'Name', 'a', 'NumMFs', 2);
     d = getFISCodeGenerationData(fis);
     size(d.parametresEntrees)      % 2x3 : deux triangles

  Voir aussi EVALFIS, GETFIS, WRITEFIS.
```

## `getTunableSettings`

```
GETTUNABLESETTINGS Paramètres réglables d'un système flou.
  [IN,OUT,RULE] = GETTUNABLESETTINGS(FIS) énumère ce qu'un réglage peut
  toucher : les paramètres des modalités d'entrée, ceux des modalités
  de sortie, et les indices des règles.

  Chaque réglage est une structure portant le nom de la variable, celui
  de la modalité, son type, les valeurs courantes et les bornes que le
  réglage ne doit pas franchir : l'intervalle de la variable élargi de
  sa propre largeur de chaque côté, et au besoin étendu pour contenir
  les paramètres actuels. Une modalité d'extrémité a en effet un pied
  hors de l'intervalle — c'est ainsi qu'elle sature —, et des bornes
  plus serrées le rentreraient de force.

  Exemple :
     fis = addInput(mamfis, [0 10], 'Name', 'a', 'NumMFs', 2);
     s = getTunableSettings(fis);
     numel(s)                       % 2 : une par modalité

  Voir aussi GETTUNABLEVALUES, SETTUNABLEVALUES, TUNEFIS.
```

## `getTunableValues`

```
GETTUNABLEVALUES Valeurs courantes des paramètres réglables.
  V = GETTUNABLEVALUES(FIS,S) rend, dans un vecteur, les paramètres que
  décrivent les réglages S — ceux que rend GETTUNABLESETTINGS —, mis
  bout à bout dans leur ordre.

  C'est ce vecteur qu'un algorithme d'optimisation manipule, et que
  SETTUNABLEVALUES repose dans le système.

  Exemple :
     fis = addInput(mamfis, [0 10], 'Name', 'a', 'NumMFs', 2);
     s = getTunableSettings(fis);
     numel(getTunableValues(fis, s))   % 6 : deux triangles

  Voir aussi GETTUNABLESETTINGS, SETTUNABLEVALUES, TUNEFIS.
```

## `getfis`

```
GETFIS Lecture d'un champ d'un système d'inférence floue.
  GETFIS(FIS) affiche le résumé du système.
  GETFIS(FIS,'name'|'type'|'numinputs'|'numoutputs'|'numrules') rend le
  champ demandé, ainsi que les cinq opérateurs par leurs noms MATLAB :
  'andmethod', 'ormethod', 'impmethod', 'aggmethod', 'defuzzmethod'.
  GETFIS(FIS,'input',I,CHAMP) lit un champ d'une variable : 'name',
  'range', 'nummfs'.
  GETFIS(FIS,'input',I,'mf',J,CHAMP) lit 'name', 'type' ou 'params'.

  Exemple :
     getfis(fis, 'numinputs')
     getfis(fis, 'input', 1, 'mf', 2, 'params')

  Voir aussi SETFIS, SHOWRULE, NEWFIS.
```

## `linsmf`

```
LINSMF Fonction d'appartenance en S linéaire.
  Y = LINSMF(X,[A B]) monte en ligne droite de zéro en A à un en B, et
  reste à zéro avant et à un après. Si B est plus petit que A, la
  courbe descend au lieu de monter.

  C'est la plus simple des courbes croissantes : là où SMF adoucit les
  deux coudes, celle-ci les garde nets, ce qui rend la règle plus
  facile à lire.

  Exemple :
     linsmf([0 2 5 8 10], [2 8])   % [0 0 0.5 1 1]

  Voir aussi LINZMF, SMF, ZMF, TRIMF, EVALMF.
```

## `linzmf`

```
LINZMF Fonction d'appartenance en Z linéaire.
  Y = LINZMF(X,[A B]) descend en ligne droite de un en A à zéro en B,
  et reste à un avant et à zéro après.

  C'est le complément de LINSMF sur le même intervalle : la somme des
  deux vaut un partout.

  Exemple :
     linzmf([0 2 5 8 10], [2 8])   % [1 1 0.5 0 0]

  Voir aussi LINSMF, ZMF, SMF, TRIMF, EVALMF.
```

## `mamfis`

```
MAMFIS Système d'inférence floue de Mamdani.
  FIS = MAMFIS crée un système vide nommé « fis ».
  FIS = MAMFIS('Name',NOM) le nomme.

  C'est la forme moderne de NEWFIS(NOM,'mamdani') : la conclusion de
  chaque règle est un ensemble flou, que l'inférence agrège puis
  défuzzifie.

  Exemple :
     fis = mamfis('Name', 'pilote');

  Voir aussi SUGFIS, NEWFIS, EVALFIS.
```

## `newfis`

```
NEWFIS Crée un système d'inférence floue.
  FIS = NEWFIS(NOM) crée un système de Mamdani vide.
  FIS = NEWFIS(NOM,TYPE) où TYPE vaut 'mamdani' ou 'sugeno'.
  FIS = NEWFIS(NOM,TYPE,ET,OU,IMPLICATION,AGREGATION,DEFUZZ) fixe les
  cinq opérateurs. Leurs valeurs par défaut sont celles de MATLAB :
  'min', 'max', 'min', 'max' et 'centroid' pour Mamdani, 'prod', 'probor',
  'prod', 'sum' et 'wtaver' pour Sugeno.

  La structure porte les champs nom, type, entrees, sorties, regles et
  les cinq opérateurs. Les variables sont des tableaux de cellules ;
  GETFIS et SETFIS donnent les accès nommés.

  Exemple :
     fis = newfis('exemple', 'sugeno');
     fis.defuzzification   % 'wtaver'

  Voir aussi MAMFIS, SUGFIS, ADDVAR, ADDMF, ADDRULE, EVALFIS.
```

## `pimf`

```
PIMF Fonction d'appartenance en Pi : montée en S puis descente en Z.
  Y = PIMF(X,[A B C D]) monte de A à B, vaut 1 de B à C, descend de C
  à D.

  Exemple :  pimf(5, [1 4 6 9])   % 1
```

## `plotfis`

```
PLOTFIS Vue d'ensemble d'un système d'inférence floue.
  PLOTFIS(FIS) écrit la structure du système : ses entrées avec leurs
  modalités, ses sorties, et le nombre de règles qui les relient.
  T = PLOTFIS(FIS) rend ce texte au lieu de l'afficher.

  Exemple :
     plotfis(fis)

  Voir aussi PLOTMF, SHOWRULE, GETFIS.
```

## `plotmf`

```
PLOTMF Tracé des fonctions d'appartenance d'une variable.
  PLOTMF(FIS,'input',I) trace, sur l'étendue de la variable, toutes ses
  fonctions d'appartenance superposées. C'est le premier regard qu'on
  porte sur un système flou : il montre si les modalités se recouvrent
  assez pour que la sortie soit continue, et si elles couvrent bien
  toute l'étendue.

  [Y,X] = PLOTMF(...) rend les courbes au lieu de les tracer, une
  colonne par fonction.

  Exemple :
     [y, x] = plotmf(fis, 'input', 1);
     max(sum(y, 2))   % somme des appartenances au point le plus couvert

  Voir aussi EVALMF, PLOTFIS, GENSURF.
```

## `poserOptions`

```
POSEROPTIONS Applique des couples nom-valeur à une structure d'options.
  Un nom qui n'est pas déjà un champ est refusé : c'est ce qui
  distingue une faute de frappe d'un réglage.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `poserVariables`

```
POSERVARIABLES Remplace la liste des entrées ou celle des sorties.
```

## `probor`

```
PROBOR Ou probabiliste, ou somme algébrique.
  Y = PROBOR(A,B) vaut A + B - A.*B. C'est la t-conorme associée au
  produit : elle remplace le maximum quand on veut que deux
  activations partielles se renforcent au lieu de s'ignorer.

  Y = PROBOR(X) applique l'opération le long des colonnes de X, ou le
  long d'un vecteur.

  Exemple :
     probor(0.5, 0.5)      % 0.75
     probor([0.5 0.5])     % 0.75

  Voir aussi MAX, MIN, EVALFIS.
```

## `psigmf`

```
PSIGMF Produit de deux sigmoïdes.
  Y = PSIGMF(X,[A1 C1 A2 C2]) = sigmf(X,[A1 C1]) .* sigmf(X,[A2 C2]).
```

## `rangDansGenre`

```
RANGDANSGENRE Rang d'une variable parmi les entrées ou parmi les sorties.
  Le nom est cherché dans le genre demandé seulement : retirer une
  entrée ne doit pas atteindre une sortie du même nom.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `readfis`

```
READFIS Lit un système d'inférence floue depuis un fichier .fis.
  FIS = READFIS(NOMFICHIER) relit le format texte de MathWorks. Les
  sections inconnues sont ignorées, ce qui rend la lecture tolérante aux
  fichiers écrits par des versions plus récentes.

  Exemple :
     fis = readfis('pilote.fis');

  Voir aussi WRITEFIS, NEWFIS.
```

## `removeInput`

```
REMOVEINPUT Retire une variable d'entrée d'un système flou.
  FIS = REMOVEINPUT(FIS,NOM) retire l'entrée nommée NOM, ou de rang NOM
  si l'on donne un nombre. La colonne correspondante disparaît de la
  matrice des règles : celles qui la mentionnaient portent désormais
  sur les autres variables.

  Exemple :
     fis = addInput(addInput(mamfis, [0 1], 'Name', 'a'), [0 1], 'Name', 'b');
     fis = removeInput(fis, 'a');
     fis.entrees{1}.nom             % 'b'

  Voir aussi REMOVEOUTPUT, REMOVEMF, REMOVERULE, ADDINPUT, RMVAR.
```

## `removeMF`

```
REMOVEMF Retire une modalité d'une variable.
  FIS = REMOVEMF(FIS,VAR,MF) retire de la variable VAR — nommée ou de
  rang — la modalité MF, nommée ou de rang. Les règles qui la
  mentionnaient sont supprimées, et celles qui nomment une modalité de
  rang supérieur sont renumérotées : sans cela elles désigneraient la
  mauvaise.

  Exemple :
     fis = addInput(mamfis, [0 1], 'Name', 'a', 'NumMFs', 3);
     fis = removeMF(fis, 'a', 'mf2');
     numel(fis.entrees{1}.mf)       % 2

  Voir aussi ADDMF, REMOVEINPUT, REMOVERULE, RMMF.
```

## `removeOutput`

```
REMOVEOUTPUT Retire une variable de sortie d'un système flou.
  FIS = REMOVEOUTPUT(FIS,NOM) retire la sortie nommée NOM, ou de rang
  NOM si l'on donne un nombre, et la colonne correspondante des règles.

  Exemple :
     fis = addOutput(mamfis, [0 1], 'Name', 'y');
     fis = removeOutput(fis, 'y');
     numel(fis.sorties)             % 0

  Voir aussi REMOVEINPUT, REMOVEMF, REMOVERULE, ADDOUTPUT, RMVAR.
```

## `removeRule`

```
REMOVERULE Retire des règles d'un système flou.
  FIS = REMOVERULE(FIS,I) retire les règles de rangs I, qui peut être
  un vecteur. Les autres gardent leur ordre.

  Exemple :
     fis = addInput(mamfis, [0 1], 'Name', 'a', 'NumMFs', 2);
     fis = addOutput(fis, [0 1], 'Name', 'b', 'NumMFs', 2);
     fis = addRule(fis, [1 1 1 1; 2 2 1 1]);
     fis = removeRule(fis, 1);
     size(fis.regles, 1)            % 1

  Voir aussi ADDRULE, SHOWRULE, REMOVEMF, REMOVEINPUT.
```

## `rmmf`

```
RMMF Retire une fonction d'appartenance d'une variable.
  FIS = RMMF(FIS,'input',I,'mf',J) retire la J-ième fonction
  d'appartenance de la I-ième entrée. 'output' fait de même sur une
  sortie.

  Les règles qui s'y référaient sont retirées, et les indices supérieurs
  sont décalés : une règle ne peut pas désigner une fonction disparue.

  Exemple :
     fis = rmmf(fis, 'input', 1, 'mf', 2);

  Voir aussi ADDMF, RMVAR, ADDRULE.
```

## `rmvar`

```
RMVAR Retire une variable d'entrée ou de sortie.
  FIS = RMVAR(FIS,'input',I) retire la I-ième entrée, et avec elle la
  colonne correspondante de la matrice des règles.

  Exemple :
     fis = rmvar(fis, 'input', 2);

  Voir aussi ADDVAR, RMMF.
```

## `setTunableValues`

```
SETTUNABLEVALUES Repose des paramètres réglés dans un système flou.
  FIS = SETTUNABLEVALUES(FIS,S,V) écrit dans le système les valeurs V,
  rangées comme les rend GETTUNABLEVALUES pour les réglages S.

  Chaque valeur est ramenée entre les bornes du réglage, et les
  paramètres d'une modalité sont remis en ordre croissant quand sa
  forme l'exige — un triangle dont le sommet passerait derrière son
  pied ne serait plus une fonction d'appartenance.

  Exemple :
     fis = addInput(mamfis, [0 10], 'Name', 'a', 'NumMFs', 2);
     s = getTunableSettings(fis);
     v = getTunableValues(fis, s);
     fis = setTunableValues(fis, s, v);   % rien n'a bougé

  Voir aussi GETTUNABLESETTINGS, GETTUNABLEVALUES, TUNEFIS.
```

## `setfis`

```
SETFIS Écriture d'un champ d'un système d'inférence floue.
  FIS = SETFIS(FIS,CHAMP,VALEUR) écrit un champ du système : 'name',
  'type', 'andmethod', 'ormethod', 'impmethod', 'aggmethod',
  'defuzzmethod'.
  FIS = SETFIS(FIS,'input',I,CHAMP,VALEUR) écrit 'name' ou 'range'.
  FIS = SETFIS(FIS,'input',I,'mf',J,CHAMP,VALEUR) écrit 'name', 'type'
  ou 'params'.

  Exemple :
     fis = setfis(fis, 'defuzzmethod', 'bisector');
     fis = setfis(fis, 'input', 1, 'mf', 2, 'params', [1 4 7]);

  Voir aussi GETFIS, NEWFIS.
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

## `subclust`

```
SUBCLUST Classification par soustraction, méthode de Chiu.
  C = SUBCLUST(X,RA) cherche les centres de classes sans qu'on ait à
  dire combien. Chaque point reçoit un potentiel, somme des influences
  de tous les autres :

     P(i) = somme_j exp(-4 ||x_i - x_j||^2 / RA^2)

  Le point de potentiel maximal devient un centre ; on retranche alors
  son influence à tous les autres, et on recommence. Un point entouré
  de voisins gagne, un point isolé perd : le nombre de classes sort du
  calcul au lieu d'y entrer.

  [C,S] = SUBCLUST(...) rend aussi les écarts types à donner aux
  fonctions d'appartenance gaussiennes construites autour des centres.

  SUBCLUST(X,RA,BORNES,OPTIONS) où OPTIONS vaut
    [ECRASEMENT ACCEPTATION REJET AFFICHAGE]
  valant par défaut [1.25 0.5 0.15 0]. L'écrasement fixe le rayon de
  soustraction, plus large que le rayon d'influence pour que deux
  centres ne se collent pas.

  Exemple :
     c = subclust([randn(50,2); randn(50,2) + 8], 0.5);

  Voir aussi FCM, GENFIS2.
```

## `subclustOptions`

```
SUBCLUSTOPTIONS Options de la classification soustractive.
  O = SUBCLUSTOPTIONS rend les réglages par défaut de SUBCLUST :
    ClusterInfluenceRange  rayon d'influence, 0,5
    DataScale              bornes de normalisation, 'auto'
    SquashFactor           écrasement du potentiel autour d'un centre,
                           1,25
    AcceptRatio            au-dessus de ce rapport, un point devient
                           centre sans discussion, 0,5
    RejectRatio            en dessous, il est écarté, 0,15
    Verbose                affichage, 0

  Exemple :
     o = subclustOptions('ClusterInfluenceRange', 0.3);
     c = subclust(donnees, o);

  Voir aussi SUBCLUST, GENFISOPTIONS, FCM.
```

## `sugfis`

```
SUGFIS Système d'inférence floue de Sugeno.
  FIS = SUGFIS crée un système vide nommé « fis ».
  FIS = SUGFIS('Name',NOM) le nomme.

  Chez Sugeno, la conclusion d'une règle n'est pas un ensemble flou mais
  une fonction des entrées, constante ou affine. Il n'y a donc rien à
  défuzzifier : la sortie est la moyenne des conclusions, pondérée par
  les forces d'activation. C'est ce qui rend ces systèmes dérivables, et
  donc apprenables — c'est sur eux que travaille ANFIS.

  Exemple :
     fis = sugfis('Name', 'approximateur');

  Voir aussi MAMFIS, NEWFIS, ANFIS, GENFIS.
```

## `trapmf`

```
TRAPMF Fonction d'appartenance trapézoïdale.
  Y = TRAPMF(X,[A B C D]) monte de zéro en A jusqu'à un en B, reste à
  un jusqu'à C, puis redescend à zéro en D.

  Comme pour TRIMF, les côtés de largeur nulle valent un sur le plateau :
  TRAPMF(X,[0 0 3 5]) est un épaulement gauche, qui vaut un en zéro.

  Exemple :
     trapmf(0:6, [1 2 4 5])   % [0 0 1 1 1 0 0]
     trapmf(0:5, [0 0 2 4])   % [1 1 1 0.5 0 0]

  Voir aussi TRIMF, PIMF, EVALMF.
```

## `trimf`

```
TRIMF Fonction d'appartenance triangulaire.
  Y = TRIMF(X,[A B C]) monte de zéro en A jusqu'à un en B, puis
  redescend à zéro en C.

  Les cas dégénérés comptent : quand A vaut B, la fonction saute à un en
  A et l'appartenance y vaut un, pas zéro — c'est l'épaulement gauche
  dont on se sert pour la modalité extrême d'une variable. De même quand
  B vaut C, à droite.

  Exemple :
     trimf(0:10, [0 5 10])   % [0 .2 .4 .6 .8 1 .8 .6 .4 .2 0]
     trimf(0:5, [0 0 5])     % [1 .8 .6 .4 .2 0]

  Voir aussi TRAPMF, GAUSSMF, EVALMF.
```

## `trouverVariable`

```
TROUVERVARIABLE Repère une variable par son nom, entrée ou sortie.
  Le nom peut aussi être le rang, auquel cas on cherche d'abord parmi
  les entrées puis parmi les sorties, comme le fait MATLAB.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `tunefis`

```
TUNEFIS Règle les paramètres d'un système flou sur des données.
  FIS = TUNEFIS(FIS0,S,X,Y) ajuste les paramètres décrits par S — ceux
  que rend GETTUNABLESETTINGS — pour que le système approche au mieux
  les sorties Y sur les entrées X. S vide veut dire « tous les
  paramètres des modalités ».

  FIS = TUNEFIS(...,OPTIONS) où OPTIONS vient de TUNEFISOPTIONS.
  [FIS,INFO] = TUNEFIS(...) rend aussi l'erreur quadratique moyenne au
  départ et à l'arrivée, et le nombre d'évaluations.

  La recherche est un simplexe de Nelder-Mead sur le vecteur des
  paramètres, chaque essai étant ramené entre les bornes des réglages.
  MATLAB propose en plus la recherche par motifs, le recuit et les
  algorithmes génétiques ; ce qu'ils apportent est la capacité de
  sortir d'un minimum local, que MatLibre n'a pas ici.

  Exemple :
     x = (0:0.25:10)';
     y = sin(x);
     fis0 = genfis1([x y], 4);
     [fis, info] = tunefis(fis0, [], x, y);
     info.ErreurFinale < info.ErreurInitiale   % vrai

  Voir aussi GETTUNABLESETTINGS, GETTUNABLEVALUES, SETTUNABLEVALUES,
  ANFIS, TUNEFISOPTIONS.
```

## `tunefisOptions`

```
TUNEFISOPTIONS Options du réglage d'un système flou.
  O = TUNEFISOPTIONS rend les réglages par défaut de TUNEFIS :
    Method            'anfis' (défaut) ou 'patternsearch' — MatLibre
                      ne connaît que la descente locale et l'hybride
                      d'ANFIS
    MethodOptions     options de la méthode
    OptimizationType  'tuning' (défaut) ou 'learning'
    Display           'all', 'none' ou 'tuningonly'
    DistributionType  répartition des modalités, 'uniform'
    IgnoreInvalidParameters  laisser passer un paramètre hors bornes
    UseParallel       calcul réparti, 0

  Exemple :
     o = tunefisOptions('Method', 'anfis');
     fis = tunefis(fis0, [], x, y, o);

  Voir aussi TUNEFIS, GETTUNABLESETTINGS, ANFISOPTIONS.
```

## `variablesDe`

```
VARIABLESDE Liste des variables d'entrée ou de sortie d'un système flou.
```

## `writefis`

```
WRITEFIS Écrit un système d'inférence floue dans un fichier .fis.
  WRITEFIS(FIS,NOMFICHIER) écrit le format texte de MathWorks : une
  section [System], une section par variable, et une section [Rules].
  L'extension .fis est ajoutée si elle manque.

  Le format est lisible et se relit par READFIS, ce qui donne un moyen
  simple de conserver un système entre deux sessions.

  Exemple :
     writefis(fis, 'pilote.fis');
     memeFis = readfis('pilote.fis');

  Voir aussi READFIS, NEWFIS.
```

## `zmf`

```
ZMF Fonction d'appartenance en Z : décroît de 1 à 0.
  Y = ZMF(X,[A B]) vaut 1 avant A, 0 après B, avec deux arcs de
  parabole raccordés au milieu — la courbe est donc dérivable.

  Exemple :  zmf(0, [2 8])   % 1
```

