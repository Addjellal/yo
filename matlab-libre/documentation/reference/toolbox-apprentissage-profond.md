# Toolbox `apprentissage-profond`

```
% Deep Learning Toolbox — réseaux de neurones.
%
% Deux façons de travailler cohabitent, comme dans MATLAB. TRAINNETWORK
% mène l'apprentissage de bout en bout à partir d'une liste de couches et
% de réglages. DLNETWORK, lui, laisse la boucle à l'utilisateur : on
% calcule la perte, on en demande les dérivées, on avance les poids — ce
% qu'il faut dès que la perte ou l'entraînement sortent de l'ordinaire.
%
% Dérivation automatique
%   dlarray             - Tableau qui retient d'où il vient
%   dlfeval             - Évalue en enregistrant le calcul
%   dlgradient          - Dérivées d'un scalaire, en mode inverse
%   extractdata         - Le tableau numérique porté
%   dims, stripdims     - Étiquettes de dimension
%   finddim             - Position d'une étiquette
%
% Opérations dérivables
%   fullyconnect        - Combinaison linéaire
%   dlconv              - Convolution, à une ou deux dimensions
%   maxpool, avgpool    - Agrégation par le maximum ou la moyenne
%   batchnorm           - Normalisation par lot
%   layernorm           - Normalisation par observation
%   groupnorm           - Normalisation par groupe de canaux
%   relu, leakyrelu     - Redresseurs
%   sigmoid, softmax    - Sorties bornées
%
% Pertes
%   crossentropy        - Entropie croisée d'un classifieur
%   mse, l2loss         - Erreur quadratique
%   l1loss              - Erreur absolue, robuste
%   huber               - Quadratique près de zéro, linéaire au loin
%
% Solveurs
%   adamupdate          - Moments adaptatifs
%   sgdmupdate          - Descente à inertie
%   rmspropupdate       - Pas normalisé par le gradient récent
%
% Réseaux
%   dlnetwork           - Réseau à boucle d'apprentissage libre
%   layerGraph          - Graphe de couches, éventuellement ramifié
%   addLayers, connectLayers - Construction d'un graphe
%   initialize          - Tirage des poids
%   forward, predict    - Passage avant, à l'apprentissage ou non
%   activations         - Sortie d'une couche intermédiaire
%   resetState          - Efface les moyennes glissantes
%   predictAndUpdateState - Prédit et conserve l'état
%   assembleNetwork     - Réseau prêt à prédire, sans apprentissage
%   analyzeNetwork      - Description couche par couche
%   trainNetwork        - Apprentissage mené de bout en bout
%   trainingOptions     - Réglages de l'apprentissage
%   classify            - Classe prédite
%
% Données
%   minibatchqueue      - Découpage en lots successifs
%   onehotencode        - Étiquettes en indicatrices
%   onehotdecode        - Indicatrices en étiquettes
%   confusionchart      - Matrice de confusion, affichée
%
% Couches d'entrée
%   featureInputLayer   - Vecteurs de caractéristiques
%   imageInputLayer     - Images
%   sequenceInputLayer  - Séquences
%
% Couches à poids
%   fullyConnectedLayer     - Couche dense
%   convolution2dLayer      - Convolution d'image
%   convolution1dLayer      - Convolution de séquence
%   transposedConv2dLayer   - Convolution transposée, qui agrandit
%   lstmLayer               - Mémoire longue
%   gruLayer                - Portes récurrentes
%   bilstmLayer             - Mémoire longue bidirectionnelle
%
% Activations
%   reluLayer, leakyReluLayer, clippedReluLayer, eluLayer
%   geluLayer, swishLayer, softplusLayer
%   sigmoidLayer, tanhLayer, softmaxLayer
%
% Normalisation et régularisation
%   batchNormalizationLayer         - Par lot
%   layerNormalizationLayer         - Par observation
%   groupNormalizationLayer         - Par groupe de canaux
%   crossChannelNormalizationLayer  - Concurrence entre canaux
%   dropoutLayer                    - Abandon, à l'apprentissage seulement
%
% Agrégation
%   maxPooling2dLayer, averagePooling2dLayer
%   maxPooling1dLayer, averagePooling1dLayer
%   globalMaxPooling2dLayer, globalAveragePooling2dLayer
%   globalAveragePooling1dLayer
%   flattenLayer                    - Des images aux vecteurs
%
% Branches
%   additionLayer           - Somme, pour les connexions résiduelles
%   multiplicationLayer     - Produit terme à terme
%   concatenationLayer      - Mise bout à bout
%   depthConcatenationLayer - Mise bout à bout des canaux
%
% Couches de sortie
%   classificationLayer     - Déclare le coût d'entropie croisée
%   regressionLayer         - Déclare le coût quadratique
```

## `adamupdate`

_Pas de bloc d'aide._

## `addLayers`

```
ADDLAYERS Ajoute des couches à un graphe, sans les raccorder.
  LG = ADDLAYERS(LG,COUCHES) ajoute les couches et leur attribue un nom
  si elles n'en portent pas. Les raccordements se posent ensuite par
  CONNECTLAYERS : c'est ce découpage qui permet de décrire une branche
  avant de savoir où elle se rebranchera.

  Exemple :
     lg = layerGraph();
     lg = addLayers(lg, {reluLayer('Name', 'relu1')});

  Voir aussi LAYERGRAPH, CONNECTLAYERS, DLNETWORK.
Les couches arrivent sous trois formes : une couche seule, une
cellule de couches, ou le tableau de structures que « [c1; c2] »
produit — la notation naturelle en MATLAB. Le tableau doit être
éclaté, sans quoi la suite prendrait ses champs pour une liste
d'arguments.
```

## `additionLayer`

```
ADDITIONLAYER Somme de plusieurs entrées de même taille.
  C = ADDITIONLAYER(N) attend N entrées et rend leur somme. C'est la
  couche des connexions résiduelles : la sortie d'un bloc est ajoutée à
  son entrée, ce qui donne au gradient un chemin direct vers les
  couches profondes et permet d'en empiler beaucoup.

  C = ADDITIONLAYER(N,'Name',NOM) nomme la couche, ce qui permet d'y
  raccorder les entrées par CONNECTLAYERS.

  Exemple :
     c = additionLayer(2, 'Name', 'somme');

  Voir aussi DEPTHCONCATENATIONLAYER, MULTIPLICATIONLAYER, LAYERGRAPH.
```

## `analyzeNetwork`

```
ANALYZENETWORK Décrit un réseau couche par couche.
  ANALYZENETWORK(RESEAU) affiche, pour chaque couche, son nom, son type,
  la taille qu'elle produit et le nombre de coefficients qu'elle
  apprend, puis le total.

  RAPPORT = ANALYZENETWORK(RESEAU) rend cette description dans une
  table, sans rien afficher.

  MATLAB ouvre une fenêtre ; MatLibre écrit un tableau, qui dit la même
  chose et se lit dans un journal.

  Exemple :
     analyzeNetwork(dlnetwork({featureInputLayer(4), fullyConnectedLayer(3)}))

  Voir aussi DLNETWORK, LAYERGRAPH.
```

## `assembleNetwork`

```
ASSEMBLENETWORK Assemble un réseau sans l'entraîner.
  RESEAU = ASSEMBLENETWORK(COUCHES) construit un réseau prêt à prédire à
  partir de couches dont les poids sont déjà donnés. C'est ce qu'il faut
  pour rejouer un réseau appris ailleurs, ou pour en modifier une couche
  sans recommencer l'apprentissage.

  COUCHES est un tableau de cellules de couches ou un LAYERGRAPH.

  Exemple :
     net = assembleNetwork({featureInputLayer(3), fullyConnectedLayer(2), ...
                            softmaxLayer()});
     Y = predict(net, randn(3, 4));

  Voir aussi DLNETWORK, TRAINNETWORK, LAYERGRAPH.
```

## `averagePooling1dLayer`

```
AVERAGEPOOLING1DLAYER Agrégation par la moyenne, en une dimension.
  C = AVERAGEPOOLING1DLAYER(T) remplace chaque fenêtre de T positions
  par sa moyenne. C'est le sous-échantillonnage d'un signal ou d'une
  séquence : la sortie est plus courte et moins bruitée.

  Options : 'Stride' (la taille de la fenêtre), 'Padding' (0 ou 'same').

  Exemple :
     c = averagePooling1dLayer(2);

  Voir aussi MAXPOOLING1DLAYER, AVERAGEPOOLING2DLAYER, AVGPOOL.
```

## `averagePooling2dLayer`

```
AVERAGEPOOLING2DLAYER Sous-échantillonnage par la moyenne.
```

## `avgpool`

```
AVGPOOL Agrégation par la moyenne.
  Y = AVGPOOL(X,FENETRE) remplace chaque fenêtre par sa moyenne. Plus
  douce que le maximum, elle garde la contribution de tous les pixels.

  Options et valeurs par défaut :
    'Stride'       la taille de la fenêtre
    'Padding'      0, ou 'same'
    'DataFormat'   le format, quand X n'en porte pas

  La moyenne porte sur la fenêtre entière, remplissage compris.

  Exemple :
     extractdata(avgpool(dlarray(reshape(1:16, 4, 4), 'SS'), 2))

  Voir aussi MAXPOOL, AVERAGEPOOLING2DLAYER.
```

## `batchNormalizationLayer`

```
BATCHNORMALIZATIONLAYER Normalisation par lot.
  Centre et réduit chaque composante sur le lot, puis applique un gain
  et un décalage appris. Les moyennes glissantes servent à la
  prédiction.
```

## `batchnorm`

```
BATCHNORM Normalisation par lot.
  Y = BATCHNORM(X,DECALAGE,ECHELLE) centre et réduit X canal par canal,
  sur toutes les observations du lot et toutes les positions spatiales,
  puis applique l'échelle et le décalage appris — un par canal.

  [Y,MU,SIGMA2] = BATCHNORM(...) rend aussi la moyenne et la variance
  du lot, à conserver pour la prédiction.

  Y = BATCHNORM(X,DECALAGE,ECHELLE,MU,SIGMA2) emploie les statistiques
  données au lieu de celles du lot : c'est ce qu'il faut faire en
  prédiction, où le résultat ne doit pas dépendre des autres exemples
  présentés en même temps.

  [Y,MU,SIGMA2] = BATCHNORM(X,DECALAGE,ECHELLE,MU0,SIGMA20,...) met à
  jour les moyennes glissantes à partir de celles données.

  Options et valeurs par défaut :
    'Epsilon'         1e-5, ajouté à la variance avant la racine
    'MeanDecay'       0.1, le poids du lot dans la moyenne glissante
    'VarianceDecay'   0.1
    'DataFormat'      le format, quand X n'en porte pas

  La normalisation par lot recentre l'entrée de chaque couche, ce qui
  permet des pas d'apprentissage plus grands sans divergence.

  Exemple :
     x = dlarray(randn(4, 4, 3, 16), 'SSCB');
     y = batchnorm(x, zeros(3, 1), ones(3, 1));

  Voir aussi LAYERNORM, GROUPNORM, BATCHNORMALIZATIONLAYER, DLARRAY.
```

## `bilstmLayer`

```
BILSTMLAYER Couche récurrente à mémoire longue, dans les deux sens.
  C = BILSTMLAYER(U) parcourt la séquence de gauche à droite et de
  droite à gauche, puis met les deux sorties bout à bout : chaque
  instant est donc décrit par ce qui le précède et par ce qui le suit.
  La sortie a deux fois U composantes.

  Le sens rétrograde interdit l'usage en temps réel — il faut la
  séquence entière —, mais il vaut beaucoup là où on l'a : étiquetage de
  texte, segmentation de signal.

  Options et valeurs par défaut :
    'OutputMode'   'sequence' ou 'last'
    'Name'         le nom de la couche

  Exemple :
     c = bilstmLayer(16);

  Voir aussi LSTMLAYER, GRULAYER, SEQUENCEINPUTLAYER.
```

## `classificationLayer`

```
CLASSIFICATIONLAYER Couche de sortie pour la classification.
  Elle déclare que le coût est l'entropie croisée ; elle n'a pas de
  paramètre et ne transforme pas la sortie.
```

## `classify`

```
CLASSIFY Classe de plus forte probabilité pour chaque observation.
```

## `clippedReluLayer`

```
CLIPPEDRELULAYER Redresseur borné.
  C = CLIPPEDRELULAYER(PLAFOND) applique min(max(X,0),PLAFOND). Le
  plafond empêche les activations de croître sans limite, ce qui rend
  l'apprentissage plus stable et la quantification possible.

  Exemple :
     c = clippedReluLayer(6);

  Voir aussi RELULAYER, LEAKYRELULAYER, ELULAYER.
```

## `concatenationLayer`

```
CONCATENATIONLAYER Mise bout à bout de plusieurs entrées.
  C = CONCATENATIONLAYER(DIM,N) met ses N entrées bout à bout selon la
  dimension DIM. Contrairement à l'addition, elle n'exige pas que les
  entrées aient la même taille selon cette dimension, et elle garde
  toute leur information.

  Exemple :
     c = concatenationLayer(1, 2, 'Name', 'jointure');

  Voir aussi DEPTHCONCATENATIONLAYER, ADDITIONLAYER, LAYERGRAPH.
```

## `confusionchart`

```
CONFUSIONCHART Matrice de confusion, affichée.
  CONFUSIONCHART(VRAIES,PREDITES) dessine la matrice qui croise les
  classes réelles et les classes prédites : la diagonale porte les
  bonnes réponses, et chaque case hors diagonale dit quelle classe a été
  prise pour quelle autre. C'est ce que la seule justesse ne dit pas.

  [M,C] = CONFUSIONCHART(...) rend la matrice et la liste des classes
  sans rien dessiner.

  CONFUSIONCHART(M,C) accepte aussi une matrice déjà calculée et la
  liste des classes.

  Options et valeurs par défaut :
    'Normalization'   'absolute', ou 'row-normalized' pour lire des
                      taux de rappel par ligne
    'Title'           le titre de la figure

  Exemple :
     confusionchart({'a','b','a'}, {'a','b','b'});

  Voir aussi CONFUSIONMAT, ONEHOTDECODE, ANALYZENETWORK.
```

## `connectLayers`

```
CONNECTLAYERS Raccorde la sortie d'une couche à l'entrée d'une autre.
  LG = CONNECTLAYERS(LG,SOURCE,DESTINATION) inscrit une arête dans le
  graphe. Une couche qui attend plusieurs entrées — une addition, une
  concaténation — reçoit ses arêtes dans l'ordre où on les pose.

  Exemple :
     lg = connectLayers(lg, 'conv1', 'somme');

  Voir aussi LAYERGRAPH, ADDLAYERS, DLNETWORK.
```

## `convolution1dLayer`

```
CONVOLUTION1DLAYER Couche de convolution sur une dimension.
  C = CONVOLUTION1DLAYER(TAILLE,FILTRES) fait glisser FILTRES filtres de
  TAILLE positions le long de la séquence. Chaque filtre détecte un
  motif temporel, où qu'il apparaisse : c'est l'équivalent, pour un
  signal, de ce qu'une convolution d'image fait d'un motif spatial.

  Options et valeurs par défaut :
    'Stride'          1
    'Padding'         0, ou 'same' pour garder la longueur
    'DilationFactor'  1 ; l'écarter élargit le champ vu sans ajouter de
                      poids, ce qui est la façon usuelle de couvrir un
                      long passé

  Exemple :
     c = convolution1dLayer(5, 16, 'Padding', 'same');

  Voir aussi CONVOLUTION2DLAYER, MAXPOOLING1DLAYER, DLCONV.
```

## `convolution2dLayer`

```
CONVOLUTION2DLAYER Couche de convolution bidimensionnelle.
  C = CONVOLUTION2DLAYER(TAILLE,FILTRES) où TAILLE est le côté du
  noyau, ou [H L]. Options : 'Stride' (pas, 1 par défaut) et 'Padding'
  (0 par défaut, ou 'same' pour garder la taille).

  Les poids sont initialisés par la règle de Glorot au premier appel de
  TRAINNETWORK, quand la profondeur d'entrée est connue.

  Exemple :
     c = convolution2dLayer(3, 8, 'Padding', 'same');
```

## `couchesConvolution`

```
COUCHESCONVOLUTION Propagation avant et arrière des couches spatiales.
  Regroupe ici ce qui touche aux images : convolution, agrégation par
  maximum ou par moyenne, aplatissement. TRAINNETWORK et PREDICT
  appellent les actions 'avant' et 'arriere'.

  [Y,C] = COUCHESCONVOLUTION('avant', C, X)
  [DELTA,GW,GB] = COUCHESCONVOLUTION('arriere', C, X, Y, DELTA)

  Les tableaux d'images sont rangés H x L x P x N : hauteur, largeur,
  plans, observations.

  Le calcul est organisé par décalage de noyau plutôt que par fenêtre :
  pour un noyau MH x ML il n'y a que MH*ML tranches à combiner, chacune
  portant d'un coup toutes les positions, tous les plans et toutes les
  images. C'est la transposition du produit par une matrice de Toeplitz,
  et cela évite les boucles sur les pixels.
```

## `crossChannelNormalizationLayer`

```
CROSSCHANNELNORMALIZATIONLAYER Normalisation locale entre canaux.
  C = CROSSCHANNELNORMALIZATIONLAYER(F) divise chaque activation par une
  fonction de la somme des carrés des activations voisines dans les
  canaux, sur une fenêtre de F canaux. Les canaux se font ainsi
  concurrence à chaque position : un canal fortement excité éteint ses
  voisins.

  Options et valeurs par défaut : 'Alpha' (1e-4), 'Beta' (0.75), 'K' (2).

  Exemple :
     c = crossChannelNormalizationLayer(5);

  Voir aussi BATCHNORMALIZATIONLAYER, GROUPNORMALIZATIONLAYER.
```

## `crossentropy`

```
CROSSENTROPY Entropie croisée moyenne par observation.
```

## `depthConcatenationLayer`

```
DEPTHCONCATENATIONLAYER Mise bout à bout selon les canaux.
  C = DEPTHCONCATENATIONLAYER(N) empile ses N entrées selon la
  dimension des canaux ; leurs tailles spatiales doivent coïncider.
  C'est la couche des blocs à branches parallèles, où plusieurs filtres
  de tailles différentes examinent la même image.

  Exemple :
     c = depthConcatenationLayer(3, 'Name', 'branches');

  Voir aussi CONCATENATIONLAYER, ADDITIONLAYER, LAYERGRAPH.
```

## `dlarray`

```
DLARRAY Tableau qui retient d'où il vient, pour être dérivé.
  X = DLARRAY(A) enveloppe le tableau A. Les opérations sur X — somme,
  produit, exponentielle, indexation — donnent d'autres DLARRAY et
  s'inscrivent au passage sur une bande d'enregistrement. DLGRADIENT
  parcourt ensuite cette bande à l'envers et rend les dérivées exactes,
  sans différence finie et sans que l'utilisateur ait à écrire la
  moindre formule de dérivée.

  X = DLARRAY(A,FORMAT) étiquette les dimensions : 'S' pour spatiale,
  'C' pour canal, 'B' pour observation, 'T' pour temps, 'U' pour non
  spécifiée. Les fonctions de couches lisent ces étiquettes pour savoir
  sur quelle dimension travailler.

  La dérivation ne s'enregistre qu'à l'intérieur de DLFEVAL : hors de
  là, un DLARRAY se comporte comme un tableau ordinaire, sans coût.

  Méthodes utiles :
     extractdata  - le tableau numérique porté
     dims         - le format
     stripdims    - le même tableau sans format
     finddim      - la position d'une étiquette

  Exemple :
     function [v, g] = carre(x)
         v = sum(x .^ 2);
         g = dlgradient(v, x);
     end
     [v, g] = dlfeval(@carre, dlarray([1 2 3]));
     extractdata(g)      % 2 4 6

  Voir aussi DLFEVAL, DLGRADIENT, DLNETWORK, EXTRACTDATA.
```

## `dlconv`

```
DLCONV Convolution dérivable, à une ou deux dimensions.
  Y = DLCONV(X,POIDS,BIAIS) convolue X par chacun des filtres et ajoute
  le biais. X est rangé en hauteur-largeur-canaux-observations, POIDS en
  hauteur-largeur-canaux-filtres, et le biais a une valeur par filtre.
  Une entrée à trois dimensions est traitée comme unidimensionnelle :
  position-canaux-observations.

  Options et valeurs par défaut :
    'Stride'          1, le pas du filtre
    'Padding'         0, un nombre, un couple, une matrice deux par
                      deux, ou 'same' pour conserver la taille
    'DilationFactor'  1, l'écartement des coefficients du filtre
    'DataFormat'      le format, quand X n'en porte pas

  Le filtre est retourné avant le produit : DLCONV calcule une
  convolution au sens propre, comme CONV2. Pour une couche apprise, la
  convention est sans effet ; elle compte quand on impose un filtre.

  L'opération est dérivable par rapport à l'entrée, aux poids et au
  biais : c'est elle qui porte l'apprentissage d'un réseau convolutif.

  Exemple :
     x = dlarray(reshape(1:9, 3, 3), 'SS');
     y = dlconv(x, ones(2, 2), 0);
     extractdata(y)      % les sommes de chaque carre de quatre

  Voir aussi DLARRAY, DLGRADIENT, CONVOLUTION2DLAYER, FULLYCONNECT.
```

## `dlfeval`

```
DLFEVAL Évalue une fonction en enregistrant de quoi la dériver.
  [...] = DLFEVAL(FONCTION,ARG1,ARG2,...) appelle FONCTION avec les
  arguments donnés, en enregistrant au passage toutes les opérations
  faites sur les DLARRAY. C'est à l'intérieur de cet appel, et là
  seulement, que DLGRADIENT peut rendre des dérivées.

  Les DLARRAY passés en arguments — y compris ceux rangés dans des
  tableaux de cellules ou des structures, comme le sont les paramètres
  d'un réseau — deviennent les feuilles du calcul : ce sont eux dont on
  pourra demander la dérivée.

  Exemple :
     function [perte, gradient] = coutQuadratique(x, cible)
         perte = sum((x - cible) .^ 2);
         gradient = dlgradient(perte, x);
     end
     [p, g] = dlfeval(@coutQuadratique, dlarray([1 2]), [0 0]);
     extractdata(g)      % 2 4

  Voir aussi DLARRAY, DLGRADIENT, ADAMUPDATE.
```

## `dlgradient`

```
DLGRADIENT Dérivées d'un scalaire par rapport à ce dont il dépend.
  [G1,G2,...] = DLGRADIENT(PERTE,X1,X2,...) rend la dérivée de PERTE —
  un DLARRAY scalaire — par rapport à chacune des variables données.
  L'appel n'a de sens qu'à l'intérieur de DLFEVAL, qui seul enregistre
  le calcul.

  Les variables peuvent être des DLARRAY, des tableaux de cellules ou
  des structures ; la dérivée rendue a la même forme, ce qui permet de
  dériver d'un coup tous les paramètres d'un réseau.

  Le parcours est en mode inverse : une seule remontée de la bande donne
  les dérivées par rapport à toutes les variables, quel qu'en soit le
  nombre. C'est ce qui rend l'apprentissage d'un réseau abordable.

  Exemple :
     function [v, g] = essai(x)
         v = sum(sin(x) .^ 2);
         g = dlgradient(v, x);
     end

  Voir aussi DLFEVAL, DLARRAY, ADAMUPDATE, SGDMUPDATE.
```

## `dlnetwork`

```
DLNETWORK Réseau dont on écrit soi-même la boucle d'apprentissage.
  NET = DLNETWORK(COUCHES) construit un réseau à partir d'un tableau de
  cellules de couches, chaînées dans l'ordre donné.
  NET = DLNETWORK(GRAPHE) part d'un LAYERGRAPH, ce qui autorise les
  branches et les connexions résiduelles.
  NET = DLNETWORK(...,EXEMPLE) initialise les poids d'après un exemple
  de données plutôt que d'après les tailles déclarées.

  Là où TRAINNETWORK mène l'apprentissage de bout en bout, un DLNETWORK
  laisse la boucle à l'utilisateur : on calcule la perte et ses dérivées
  par DLFEVAL et DLGRADIENT, puis on avance les poids par le solveur de
  son choix. C'est ce qu'il faut dès que la perte n'est pas une des
  pertes prévues, ou que l'apprentissage a plusieurs réseaux en jeu.

  Propriétés :
     Layers, Names, Connections  - la structure du réseau
     Learnables                  - table couche, paramètre, valeur
     State                       - les moyennes glissantes, s'il y en a
     InputNames, OutputNames     - les couches d'entrée et de sortie
     Initialized                 - les poids sont-ils tirés

  Méthodes : FORWARD (à l'apprentissage), PREDICT (en prédiction),
  INITIALIZE, RESETSTATE, PREDICTANDUPDATESTATE, ACTIVATIONS.

  Exemple :
     net = dlnetwork({featureInputLayer(2), fullyConnectedLayer(8), ...
                      reluLayer(), fullyConnectedLayer(3), softmaxLayer()});
     Y = predict(net, dlarray(randn(2, 5), 'CB'));

  Voir aussi DLFEVAL, DLGRADIENT, ADAMUPDATE, LAYERGRAPH, TRAINNETWORK.
```

## `dropoutLayer`

```
DROPOUTLAYER Couche d'abandon : éteint des unités pendant l'apprentissage.
  C = DROPOUTLAYER(P) éteint chaque unité avec la probabilité P et
  divise le reste par 1-P, de sorte que l'espérance ne change pas.
  À la prédiction, la couche est transparente.
```

## `eluLayer`

```
ELULAYER Couche ELU : linéaire pour les positifs, exponentielle sinon.
  C = ELULAYER(ALPHA) ; ALPHA vaut 1 par défaut.
```

## `featureInputLayer`

```
FEATUREINPUTLAYER Couche d'entrée pour des vecteurs de caractéristiques.
```

## `flattenLayer`

```
FLATTENLAYER Aplatit un lot d'images en vecteurs.
  Un tableau H x L x P x N devient une matrice (H*L*P) x N, prête pour
  les couches entièrement connectées.
```

## `fullyConnectedLayer`

```
FULLYCONNECTEDLAYER Couche entièrement connectée de N sorties.
  Les poids sont initialisés par la règle de Glorot une fois la taille
  d'entrée connue, au premier appel de TRAINNETWORK.
```

## `fullyconnect`

```
FULLYCONNECT Combinaison linéaire de toutes les entrées.
  Y = FULLYCONNECT(X,POIDS,BIAIS) rend POIDS*X + BIAIS. X a une colonne
  par observation, POIDS une ligne par sortie et une colonne par entrée.

  Quand X porte plus de deux dimensions — une image, par exemple —, les
  dimensions autres que celle des observations sont d'abord mises bout à
  bout : c'est ce que fait MATLAB, et c'est ce qui permet de brancher
  une couche dense derrière une couche convolutive sans rien aplatir à
  la main.

  FULLYCONNECT(...,'DataFormat',F) donne le format quand X n'en porte
  pas ; seule la position de la dimension d'observation compte.

  L'opération est dérivable : employée dans DLFEVAL, elle rend ses
  dérivées par rapport à X, aux poids et au biais.

  Exemple :
     y = fullyconnect(dlarray([1; 2], 'CB'), [1 0; 0 1; 1 1], [0; 0; 0]);
     extractdata(y)      % 1 ; 2 ; 3

  Voir aussi DLARRAY, FULLYCONNECTEDLAYER, DLCONV, DLGRADIENT.
```

## `geluLayer`

```
GELULAYER Unité linéaire à porte gaussienne.
  C = GELULAYER() applique X fois la probabilité qu'une gaussienne
  centrée réduite soit inférieure à X. Le redresseur décide brutalement
  de garder ou d'annuler ; celle-ci pondère continûment, ce qui la rend
  dérivable partout et lui vaut sa place dans les transformeurs.

  Exemple :
     c = geluLayer('Name', 'gelu1');

  Voir aussi RELULAYER, SWISHLAYER, SOFTPLUSLAYER.
```

## `globalAveragePooling1dLayer`

```
GLOBALAVERAGEPOOLING1DLAYER Moyenne sur toute la dimension de temps.
  C = GLOBALAVERAGEPOOLING1DLAYER() remplace chaque canal par la moyenne
  de ses valeurs sur toute la séquence. La sortie a donc une taille
  fixe, quelle que soit la longueur de l'entrée : c'est ce qui permet de
  brancher une couche dense derrière des séquences de longueurs
  inégales.

  Exemple :
     c = globalAveragePooling1dLayer();

  Voir aussi GLOBALAVERAGEPOOLING2DLAYER, AVERAGEPOOLING1DLAYER.
```

## `globalAveragePooling2dLayer`

```
GLOBALAVERAGEPOOLING2DLAYER Moyenne sur toute l'image, canal par canal.
  C = GLOBALAVERAGEPOOLING2DLAYER() rend un nombre par canal : la
  moyenne de sa carte d'activation. Elle remplace avantageusement les
  couches denses de fin de réseau convolutif — elle n'a aucun poids, et
  accepte des images de n'importe quelle taille.

  Exemple :
     c = globalAveragePooling2dLayer('Name', 'moyenne');

  Voir aussi GLOBALMAXPOOLING2DLAYER, AVERAGEPOOLING2DLAYER.
```

## `globalMaxPooling2dLayer`

```
GLOBALMAXPOOLING2DLAYER Maximum sur toute l'image, canal par canal.
  C = GLOBALMAXPOOLING2DLAYER() rend un nombre par canal : le maximum de
  sa carte d'activation, c'est-à-dire la réponse la plus forte du motif
  que ce canal détecte, où qu'il se trouve dans l'image.

  Exemple :
     c = globalMaxPooling2dLayer();

  Voir aussi GLOBALAVERAGEPOOLING2DLAYER, MAXPOOLING2DLAYER.
```

## `groupNormalizationLayer`

```
GROUPNORMALIZATIONLAYER Normalisation par groupe de canaux.
  C = GROUPNORMALIZATIONLAYER(G) partage les canaux en G groupes et
  normalise chacun séparément, observation par observation. Elle occupe
  le milieu entre la normalisation par couche — un seul groupe — et la
  normalisation par instance — un groupe par canal.

  G peut aussi valoir 'channel-wise' ou 'all-channels'.
  Option : 'Epsilon' (1e-5).

  Exemple :
     c = groupNormalizationLayer(4);

  Voir aussi BATCHNORMALIZATIONLAYER, LAYERNORMALIZATIONLAYER, GROUPNORM.
```

## `groupnorm`

```
GROUPNORM Normalisation par groupe de canaux.
  Y = GROUPNORM(X,DECALAGE,ECHELLE,GROUPES) partage les canaux en
  GROUPES paquets et normalise chaque paquet séparément, observation par
  observation. Avec un seul groupe, c'est la normalisation par couche ;
  avec autant de groupes que de canaux, la normalisation par instance.

  GROUPES peut aussi valoir 'channel-wise', qui prend un groupe par
  canal, ou 'all-channels', qui n'en fait qu'un.

  Options et valeurs par défaut :
    'Epsilon'      1e-5
    'DataFormat'   le format, quand X n'en porte pas

  Exemple :
     x = dlarray(randn(4, 4, 6, 3), 'SSCB');
     y = groupnorm(x, zeros(6, 1), ones(6, 1), 3);

  Voir aussi BATCHNORM, LAYERNORM, GROUPNORMALIZATIONLAYER.
```

## `gruLayer`

```
GRULAYER Couche récurrente à portes.
  C = GRULAYER(U) tient un seul état de U composantes, gouverné par deux
  portes : l'une décide de ce qu'on oublie, l'autre de la part de neuf
  qu'on écrit. Elle fait à peu près ce que fait une mémoire longue, avec
  un tiers de poids en moins et sans état de cellule séparé.

  Options et valeurs par défaut :
    'OutputMode'   'sequence' ou 'last'
    'Name'         le nom de la couche

  Exemple :
     c = gruLayer(32, 'OutputMode', 'last');

  Voir aussi LSTMLAYER, BILSTMLAYER, SEQUENCEINPUTLAYER.
```

## `huber`

```
HUBER Perte quadratique près de zéro, linéaire au loin.
  P = HUBER(Y,T) vaut la moitié du carré de l'écart tant que celui-ci
  reste sous le point de transition, et devient linéaire au-delà, en se
  raccordant sans rupture de pente.

  Elle joint les deux qualités : la courbure de la perte quadratique
  près de la solution, qui fait converger vite, et la robustesse de la
  perte absolue au loin, qui empêche une observation aberrante de tout
  emporter.

  Options et valeurs par défaut :
    'TransitionPoint'       1, le seuil de passage
    'Reduction'             'sum', ou 'none'
    'NormalizationFactor'   'batch-size', 'all-elements' ou 'none'
    'DataFormat'            le format, quand Y n'en porte pas

  Exemple :
     huber(dlarray([0.5 5], 'CB'), [0 0])      % (0.125 + 4.5) / 2

  Voir aussi L1LOSS, L2LOSS, MSE.
```

## `imageInputLayer`

```
IMAGEINPUTLAYER Couche d'entrée pour des images.
  C = IMAGEINPUTLAYER([H L P]) déclare des images de H lignes, L
  colonnes et P plans. Les données passées à TRAINNETWORK sont alors un
  tableau H x L x P x N, une image par tranche.

  Exemple :
     couches = {imageInputLayer([8 8 1]), convolution2dLayer(3, 4), ...
                reluLayer(), maxPooling2dLayer(2), flattenLayer(), ...
                fullyConnectedLayer(2), softmaxLayer()};
```

## `l1loss`

```
L1LOSS Somme des écarts absolus.
  P = L1LOSS(Y,T) rend la somme des valeurs absolues des écarts,
  divisée par le nombre d'observations.

  Cette perte pénalise proportionnellement à l'écart, là où la perte
  quadratique pénalise au carré : une observation aberrante y pèse
  beaucoup moins, ce qui rend l'ajustement robuste.

  Options et valeurs par défaut :
    'Reduction'             'sum', ou 'none' pour garder les termes
    'NormalizationFactor'   'batch-size', 'all-elements' ou 'none'
    'DataFormat'            le format, quand Y n'en porte pas

  Exemple :
     l1loss(dlarray([1 2], 'CB'), [0 0])      % 1.5

  Voir aussi L2LOSS, HUBER, MSE, CROSSENTROPY.
```

## `l2loss`

```
L2LOSS Somme des carrés des écarts.
  P = L2LOSS(Y,T) rend la somme des carrés des écarts, divisée par le
  nombre d'observations.

  Options et valeurs par défaut :
    'Reduction'             'sum', ou 'none'
    'NormalizationFactor'   'batch-size', 'all-elements' ou 'none'
    'DataFormat'            le format, quand Y n'en porte pas

  Exemple :
     l2loss(dlarray([1 2], 'CB'), [0 0])      % 2.5

  Voir aussi L1LOSS, HUBER, MSE.
```

## `layerGraph`

```
LAYERGRAPH Graphe de couches, éventuellement ramifié.
  LG = LAYERGRAPH(COUCHES) construit un graphe où les couches se suivent
  dans l'ordre donné. COUCHES est un tableau de cellules de couches.

  LG = LAYERGRAPH() construit un graphe vide, qu'on remplit par
  ADDLAYERS puis qu'on raccorde par CONNECTLAYERS. C'est ainsi qu'on
  décrit un réseau qui n'est pas une simple chaîne : une connexion
  résiduelle, deux branches parallèles réunies plus loin.

  Le graphe est une structure de trois champs : Layers, les couches ;
  Names, leurs noms — attribués d'après leur type quand ils manquent —
  et Connections, une table de deux colonnes qui dit ce qui alimente
  quoi.

  Exemple :
     lg = layerGraph({featureInputLayer(4), fullyConnectedLayer(3), ...
                      softmaxLayer()});
     height(lg.Connections)      % 2

  Voir aussi ADDLAYERS, CONNECTLAYERS, DLNETWORK, TRAINNETWORK.
```

## `layerNormalizationLayer`

```
LAYERNORMALIZATIONLAYER Normalisation par observation.
  C = LAYERNORMALIZATIONLAYER() centre et réduit chaque observation sur
  ses propres canaux, puis applique un gain et un décalage appris. Le
  résultat d'une observation ne dépend d'aucune autre : la couche
  fonctionne donc avec un lot d'un seul exemple, là où la normalisation
  par lot demande un lot fourni.

  Option : 'Epsilon' (1e-5).

  Exemple :
     c = layerNormalizationLayer('Name', 'norme');

  Voir aussi BATCHNORMALIZATIONLAYER, GROUPNORMALIZATIONLAYER, LAYERNORM.
```

## `layernorm`

```
LAYERNORM Normalisation par couche.
  Y = LAYERNORM(X,DECALAGE,ECHELLE) centre et réduit chaque observation
  sur toutes ses dimensions sauf celle du lot : contrairement à la
  normalisation par lot, le résultat d'une observation ne dépend
  d'aucune autre. C'est ce qui la rend utilisable quand le lot est
  petit, ou quand les observations n'ont pas la même longueur.

  Options et valeurs par défaut :
    'Epsilon'              1e-5
    'OperationDimension'   'auto' — toutes les dimensions sauf le lot —
                           ou 'channel-only'
    'DataFormat'           le format, quand X n'en porte pas

  Exemple :
     x = dlarray(randn(6, 8), 'CB');
     y = layernorm(x, 0, 1);
     round(mean(extractdata(y), 1), 10)      % des zéros

  Voir aussi BATCHNORM, GROUPNORM, LAYERNORMALIZATIONLAYER.
```

## `leakyReluLayer`

```
LEAKYRELULAYER Couche ReLU à fuite : pente non nulle pour les négatifs.
  C = LEAKYRELULAYER(PENTE) ; PENTE vaut 0,01 par défaut.
```

## `leakyrelu`

```
LEAKYRELU Redresseur à fuite : X si X est positif, PENTE fois X sinon.
  Y = LEAKYRELU(X) applique une pente de 0,01 aux valeurs négatives.
  Y = LEAKYRELU(X,PENTE) impose la pente.

  Le redresseur ordinaire annule tout le négatif, et la dérivée avec :
  une unité qui y tombe n'apprend plus. La fuite lui laisse un gradient,
  petit mais non nul.

  X peut être un DLARRAY.

  Exemple :
     leakyrelu([-2 3], 0.1)      % -0.2  3

  Voir aussi RELU, LEAKYRELULAYER, ELULAYER.
```

## `lstmLayer`

```
LSTMLAYER Couche récurrente à mémoire longue.
  C = LSTMLAYER(U) parcourt la séquence en gardant deux états de U
  composantes : une mémoire, qui traverse le temps presque sans être
  modifiée, et une sortie. Trois portes — oubli, entrée, sortie —
  décident à chaque instant de ce qu'on efface, de ce qu'on écrit et de
  ce qu'on montre.

  C'est la mémoire qui fait tout : parce qu'elle se transmet par une
  addition et non par un produit de matrices, le gradient la remonte
  sans s'évanouir, et le réseau peut relier des instants éloignés.

  Options et valeurs par défaut :
    'OutputMode'   'sequence', qui rend toute la suite des sorties, ou
                   'last', qui n'en rend que la dernière — ce qu'il faut
                   pour classer une séquence entière
    'Name'         le nom de la couche

  Exemple :
     couches = {sequenceInputLayer(3), lstmLayer(16, 'OutputMode', 'last'), ...
                fullyConnectedLayer(2), softmaxLayer()};

  Voir aussi GRULAYER, BILSTMLAYER, SEQUENCEINPUTLAYER.
```

## `matlibre_bande`

```
MATLIBRE_BANDE Bande d'enregistrement de la dérivation automatique.
  MATLIBRE_BANDE('ouvrir') vide la bande et commence à enregistrer.
  MATLIBRE_BANDE('fermer') arrête l'enregistrement.
  N = MATLIBRE_BANDE('ajouter',OPERATION,PARENTS,DONNEES) ajoute un
  nœud et rend son numéro, ou zéro si la bande est fermée.
  NOEUDS = MATLIBRE_BANDE('lire') rend tous les nœuds enregistrés.
  V = MATLIBRE_BANDE('actif') dit si l'enregistrement est en cours.

  Chaque opération sur un DLARRAY ajoute un nœud qui retient de quoi
  elle est issue et ce qu'il faut pour la dériver. Comme les nœuds sont
  ajoutés dans l'ordre du calcul, les parcourir à l'envers suffit à
  propager la dérivée : c'est la dérivation en mode inverse, qui donne
  toutes les dérivées partielles d'un scalaire pour le prix d'un seul
  parcours.

  Exemple :
     matlibre_bande('ouvrir');
     x = dlarray(3);
     y = x * x;
     matlibre_bande('nombre')     % trois nœuds
     matlibre_bande('fermer');

  Voir aussi DLARRAY, DLFEVAL, DLGRADIENT.
```

## `matlibre_couche_agregation`

```
MATLIBRE_COUCHE_AGREGATION Pas et remplissage d'une couche d'agrégation.
  [PAS,MARGE] = MATLIBRE_COUCHE_AGREGATION(TAILLE,ARGUMENTS) rend le pas
  — la taille de la fenêtre par défaut, comme dans MATLAB — et le
  remplissage.

  Exemple :
     [p, m] = matlibre_couche_agregation(2, {'Stride', 1});

  Voir aussi MAXPOOLING1DLAYER, AVERAGEPOOLING1DLAYER.
```

## `matlibre_couche_appliquer`

```
MATLIBRE_COUCHE_APPLIQUER Passage avant d'une couche.
  [Y,ETAT] = MATLIBRE_COUCHE_APPLIQUER(COUCHE,ENTREES,PARAMETRES,ETAT,
  APPRENTISSAGE) applique la couche aux entrées — un tableau de cellules,
  car une couche d'addition ou de concaténation en a plusieurs — et rend
  sa sortie ainsi que son état mis à jour.

  APPRENTISSAGE distingue les couches qui ne se comportent pas de même
  aux deux régimes : l'abandon n'agit qu'à l'apprentissage, et la
  normalisation par lot emploie alors les statistiques du lot plutôt que
  celles accumulées.

  Tout est écrit avec des opérations sur DLARRAY : la dérivée de la
  couche s'obtient donc sans qu'on l'écrive.

  Exemple :
     y = matlibre_couche_appliquer(reluLayer(), {dlarray([-1 2])}, ...
                                   struct(), struct(), true);
     extractdata(y)      % 0 2

  Voir aussi DLNETWORK, FORWARD, PREDICT.
```

## `matlibre_couche_initialiser`

```
MATLIBRE_COUCHE_INITIALISER Poids de départ d'une couche, et sa sortie.
  [P,T,S] = MATLIBRE_COUCHE_INITIALISER(COUCHE,TAILLEENTREE,SEQUENCE)
  rend les paramètres appris de la couche, la taille qu'elle produit, et
  si sa sortie est une séquence.

  Les poids suivent la règle de Glorot : tirés uniformément dans un
  intervalle inversement proportionnel à la racine du nombre d'entrées
  et de sorties. C'est ce qui garde la variance du signal d'une couche à
  la suivante — sans quoi un réseau profond sature ou s'éteint dès le
  premier passage.

  La taille s'entend hors observations : un nombre pour un vecteur de
  caractéristiques, trois pour une image.

  Exemple :
     [p, t] = matlibre_couche_initialiser(fullyConnectedLayer(3), 4, false);
     size(p.Weights)      % 3 4

  Voir aussi DLNETWORK, INITIALIZE, MATLIBRE_COUCHE_APPLIQUER.
```

## `matlibre_couche_mode`

```
MATLIBRE_COUCHE_MODE Mode de sortie d'une couche récurrente.
  M = MATLIBRE_COUCHE_MODE(ARGUMENTS) lit l'option 'OutputMode' :
  'sequence' rend toute la suite des sorties, 'last' seulement la
  dernière.

  Exemple :
     matlibre_couche_mode({'OutputMode', 'last'})     % last

  Voir aussi LSTMLAYER, GRULAYER, BILSTMLAYER.
```

## `matlibre_couche_nom`

```
MATLIBRE_COUCHE_NOM Nom donné à une couche, ou chaîne vide.
  N = MATLIBRE_COUCHE_NOM(ARGUMENTS) lit l'option 'Name' parmi les
  arguments d'un constructeur de couche. Sans nom, LAYERGRAPH en
  attribuera un, tiré du type de la couche.

  Exemple :
     matlibre_couche_nom({'Name', 'conv1'})      % conv1

  Voir aussi LAYERGRAPH, DLNETWORK.
```

## `matlibre_couche_recurrente`

```
MATLIBRE_COUCHE_RECURRENTE Passage avant d'une couche récurrente.
  Y = MATLIBRE_COUCHE_RECURRENTE(COUCHE,X,PARAMETRES) parcourt la
  séquence instant par instant en entretenant un état. X est rangé en
  canaux-observations-temps.

  Selon le type de la couche, l'état est une mémoire et une sortie
  (mémoire longue), un seul vecteur gouverné par deux portes (portes
  récurrentes), ou deux parcours en sens contraires mis bout à bout
  (mémoire longue bidirectionnelle).

  Le déroulement est écrit avec des opérations sur DLARRAY : la
  rétropropagation dans le temps s'obtient donc sans qu'on l'écrive,
  c'est la bande qui garde le fil des instants.

  Exemple :
     % appelée par le réseau, jamais directement

  Voir aussi LSTMLAYER, GRULAYER, BILSTMLAYER, DLNETWORK.
```

## `matlibre_couche_rognage`

```
MATLIBRE_COUCHE_ROGNAGE Ce qu'on retire des bords d'une convolution transposée.
  B = MATLIBRE_COUCHE_ROGNAGE(SPEC,GRANDE,ENTREE,PAS) rend
  [haut bas gauche droite]. SPEC vaut un nombre, un couple, ou 'same' —
  qui rogne de façon que la sortie fasse exactement l'entrée multipliée
  par le pas.

  Exemple :
     matlibre_couche_rognage('same', [10 10], [5 5], [2 2])

  Voir aussi TRANSPOSEDCONV2DLAYER.
```

## `matlibre_dessiner_confusion`

```
MATLIBRE_DESSINER_CONFUSION Dessine une matrice de confusion.
  MATLIBRE_DESSINER_CONFUSION(MATRICE,CLASSES,TITRE) trace la matrice en
  fausses couleurs et écrit l'effectif dans chaque case. Le texte est
  clair sur les cases foncées, sombre sur les claires, pour rester
  lisible partout.

  Exemple :
     matlibre_dessiner_confusion([2 0; 1 3], {'a','b'}, 'essai');

  Voir aussi CONFUSIONCHART.
```

## `matlibre_dl_agregation_publique`

```
MATLIBRE_DL_AGREGATION_PUBLIQUE Corps commun de MAXPOOL et AVGPOOL.
  [Y,P,T] = MATLIBRE_DL_AGREGATION_PUBLIQUE(GENRE,X,FENETRE,ARGUMENTS)
  lit les options, replie une entrée unidimensionnelle, appelle
  l'agrégation et inscrit le nœud qui la rend dérivable.

  Exemple :
     y = matlibre_dl_agregation_publique('max', dlarray(magic(4), 'SS'), 2, {});

  Voir aussi MAXPOOL, AVGPOOL.
```

## `matlibre_dl_agreger`

```
MATLIBRE_DL_AGREGER Agrégation par le maximum ou la moyenne.
  [Y,C] = MATLIBRE_DL_AGREGER(X,GENRE,FENETRE,PAS,BORDS) parcourt X par
  fenêtres et n'en garde que le maximum ou la moyenne. C retient de quoi
  dériver.

  L'agrégation se fait canal par canal : les canaux sont donc traités
  comme autant d'observations supplémentaires, ce qui permet de
  réemployer la mise à plat des voisinages écrite pour la convolution.

  Le remplissage vaut moins l'infini pour le maximum — une case ajoutée
  ne peut pas gagner — et zéro pour la moyenne, qui divise par la
  fenêtre entière.

  Exemple :
     y = matlibre_dl_agreger(reshape(1:16, 4, 4), 'max', [2 2], [2 2], [0 0 0 0]);
     y(1, 1)     % 6

  Voir aussi MAXPOOL, AVGPOOL, MAXPOOLING2DLAYER.
```

## `matlibre_dl_aplatir`

```
MATLIBRE_DL_APLATIR Met les observations en colonnes.
  Y = MATLIBRE_DL_APLATIR(X,OBSERVATIONS,TAILLE) rend une matrice dont
  chaque colonne est une observation, toutes ses autres dimensions
  mises bout à bout. C'est le passage d'un tenseur d'images à la matrice
  qu'attend une couche dense.

  Exemple :
     size(matlibre_dl_aplatir(zeros(4, 4, 3, 8), 4, [4 4 3 8]))   % 48 8

  Voir aussi FULLYCONNECT, FLATTENLAYER.
```

## `matlibre_dl_axe_canal`

```
MATLIBRE_DL_AXE_CANAL Positions des dimensions de canal et d'observation.
  [C,B,N] = MATLIBRE_DL_AXE_CANAL(X,FORMAT) rend la position de
  l'étiquette 'C', celle de 'B', et le nombre de dimensions. Sans
  format, la convention est celle de MATLAB : les observations en
  dernier, les canaux juste avant.

  Exemple :
     [c, b] = matlibre_dl_axe_canal(zeros(4, 4, 3, 8), 'SSCB');   % 3, 4

  Voir aussi BATCHNORM, LAYERNORM, GROUPNORM.
```

## `matlibre_dl_binaire`

```
MATLIBRE_DL_BINAIRE Enregistre une opération à deux opérandes.
  Y = MATLIBRE_DL_BINAIRE(OPERATION,A,B,VALEUR,DONNEES) fabrique le
  DLARRAY qui porte VALEUR et inscrit sur la bande le nœud qui le relie
  à A et à B, avec ce dont la dérivation aura besoin.

  Exemple :
     y = matlibre_dl_binaire('plus', dlarray(1), 2, 3, {[1 1], [1 1]});

  Voir aussi DLARRAY, MATLIBRE_BANDE, MATLIBRE_GRADIENT_OPERATION.
```

## `matlibre_dl_combiner`

```
MATLIBRE_DL_COMBINER Applique une règle à tous les paramètres à la fois.
  [...] = MATLIBRE_DL_COMBINER(FONCTION,A,B,...) parcourt en parallèle
  des conteneurs de même forme — DLARRAY, tableaux de cellules,
  structures, tables de paramètres — et appelle FONCTION sur chaque
  feuille numérique. Les sorties ont la forme du premier conteneur.

  Ce que la fonction ne sait pas traiter — un nom de couche, par
  exemple — est recopié tel quel : une table de paramètres se met ainsi
  à jour sans qu'on ait à en extraire la colonne des valeurs.

  C'est ce parcours qui permet aux solveurs de mettre à jour d'un seul
  appel tous les poids d'un réseau, quelle que soit la façon dont
  l'utilisateur les a rangés.

  Exemple :
     s = matlibre_dl_combiner(@(a, b) a + b, {1, 2}, {10, 20});
     s{2}      % 22

  Voir aussi ADAMUPDATE, SGDMUPDATE, RMSPROPUPDATE.
```

## `matlibre_dl_concatener`

```
MATLIBRE_DL_CONCATENER Mise bout à bout de DLARRAY, avec sa dérivée.
  Y = MATLIBRE_DL_CONCATENER(DIMENSION,OPERANDES) concatène le contenu
  des opérandes le long de DIMENSION. À la dérivation, le gradient est
  redécoupé et rendu à chacun.

  Exemple :
     y = matlibre_dl_concatener(2, {dlarray(1), dlarray(2)});
     extractdata(y)     % 1 2

  Voir aussi DLARRAY, CAT.
```

## `matlibre_dl_construire`

```
MATLIBRE_DL_CONSTRUIRE Attache un résultat à un nœud existant.
  Y = MATLIBRE_DL_CONSTRUIRE(VALEUR,FORMAT,NOEUD) fabrique le DLARRAY
  qui porte VALEUR et se rattache au nœud déjà enregistré. Le
  constructeur public, lui, crée toujours une feuille : il sert aux
  données qui entrent dans le calcul, pas aux résultats intermédiaires.

  Exemple :
     y = matlibre_dl_construire([1 2], 'CB', 0);
     extractdata(y)     % 1 2

  Voir aussi DLARRAY, MATLIBRE_BANDE.
```

## `matlibre_dl_convoluer`

```
MATLIBRE_DL_CONVOLUER Convolution par mise à plat des voisinages.
  [Y,C] = MATLIBRE_DL_CONVOLUER(X,POIDS,BIAIS,PAS,BORDS,DILATATION)
  calcule la convolution en rangeant chaque voisinage lu par le filtre
  dans une colonne, ce qui ramène l'opération à un produit de matrices.
  C retient de quoi la dériver.

  Le filtre est retourné avant le produit : c'est une convolution au
  sens propre, comme CONV2, et non une corrélation. Pour une couche dont
  les poids sont appris, la convention ne change rien — le réseau
  apprend le filtre retourné —, mais elle compte dès qu'on impose un
  filtre connu.

  Exemple :
     y = matlibre_dl_convoluer(ones(3,3,1), ones(2,2,1,1), 0, [1 1], [0 0 0 0], [1 1]);
     y(1, 1)     % 4

  Voir aussi DLCONV, MATLIBRE_GRADIENT_CONVOLUTION.
```

## `matlibre_dl_convolution_transposee`

```
MATLIBRE_DL_CONVOLUTION_TRANSPOSEE Convolution qui agrandit l'image.
  Y = MATLIBRE_DL_CONVOLUTION_TRANSPOSEE(X,POIDS,BIAIS,PAS,ROGNAGE) fait
  le chemin inverse d'une convolution : chaque point d'entrée est étalé
  sur un voisinage de la sortie, et les étalements se recouvrent.

  Le calcul est celui-là même que dit la définition : on écarte les
  points d'entrée en intercalant des zéros — un de moins que le pas —,
  puis on convolue. L'opération obtenue est exactement l'adjointe de la
  convolution de mêmes poids et de même pas, ce qui est la propriété
  qu'on attend d'elle.

  Les poids sont rangés comme dans MATLAB : hauteur, largeur, filtres,
  canaux d'entrée.

  Exemple :
     y = matlibre_dl_convolution_transposee(dlarray(ones(2,2,1,1), 'SSCB'), ...
                                            ones(3,3,1,1), 0, [2 2], 0);
     size(extractdata(y))      % 5 5 1 1

  Voir aussi TRANSPOSEDCONV2DLAYER, DLCONV.
```

## `matlibre_dl_couple`

```
MATLIBRE_DL_COUPLE Un réglage donné pour les deux dimensions spatiales.
  C = MATLIBRE_DL_COUPLE(V) rend un couple : un nombre unique vaut pour
  les deux dimensions, un couple est rendu tel quel.

  Exemple :
     matlibre_dl_couple(2)     % 2 2

  Voir aussi DLCONV.
```

## `matlibre_dl_dimension`

```
MATLIBRE_DL_DIMENSION Dimension visée par une somme ou une moyenne.
  D = MATLIBRE_DL_DIMENSION(VALEUR,ARGUMENTS) lit les arguments passés
  après le tableau : rien donne la première dimension non singleton,
  'all' donne zéro — le tableau entier —, un nombre se lit tel quel.

  Exemple :
     matlibre_dl_dimension(zeros(1, 5), {})       % 2
     matlibre_dl_dimension(zeros(3), {'all'})     % 0

  Voir aussi DLARRAY.
```

## `matlibre_dl_effectif`

```
MATLIBRE_DL_EFFECTIF Par quoi diviser une perte cumulée.
  N = MATLIBRE_DL_EFFECTIF(Y,FACTEUR,FORMAT) rend le nombre
  d'observations pour 'batch-size', le nombre d'éléments pour
  'all-elements', et un pour 'none'.

  Exemple :
     matlibre_dl_effectif(zeros(3, 8), 'batch-size', 'CB')     % 8

  Voir aussi L1LOSS, L2LOSS, HUBER, CROSSENTROPY.
```

## `matlibre_dl_entree`

```
MATLIBRE_DL_ENTREE Données d'entrée, en DLARRAY.
  X = MATLIBRE_DL_ENTREE(D) enveloppe D si ce n'en est pas déjà un, et
  lui donne le format qu'impose sa forme.

  Exemple :
     dims(matlibre_dl_entree(zeros(3, 8)))      % CB

  Voir aussi DLNETWORK, DLARRAY.
```

## `matlibre_dl_est_unidimensionnel`

```
MATLIBRE_DL_EST_UNIDIMENSIONNEL La convolution ne porte-t-elle que sur une
  dimension ?
  OUI = MATLIBRE_DL_EST_UNIDIMENSIONNEL(X,POIDS,FORMAT) répond d'après
  le format quand il y en a un — une seule étiquette spatiale —, sinon
  d'après le nombre de dimensions des poids : trois pour un filtre
  unidimensionnel, quatre pour un filtre d'image.

  Exemple :
     matlibre_dl_est_unidimensionnel(zeros(8, 2, 4), zeros(3, 2, 5), 'SCB')

  Voir aussi DLCONV.
```

## `matlibre_dl_extraire_observations`

```
MATLIBRE_DL_EXTRAIRE_OBSERVATIONS Sous-ensemble d'observations.
  L = MATLIBRE_DL_EXTRAIRE_OBSERVATIONS(D,INDICES) prend les
  observations demandées, quelle que soit la dimension des données : la
  dernière dimension est celle des observations.

  Exemple :
     size(matlibre_dl_extraire_observations(zeros(4, 4, 1, 10), 1:3))

  Voir aussi MINIBATCHQUEUE.
```

## `matlibre_dl_extremum`

```
MATLIBRE_DL_EXTREMUM Maximum ou minimum d'un DLARRAY, avec sa dérivée.
  [Y,I] = MATLIBRE_DL_EXTREMUM(GENRE,A,B,ARGUMENTS) traite les deux
  formes : comparaison terme à terme de A et B, ou extremum le long
  d'une dimension. La dérivée ne passe que par l'opérande qui a gagné —
  c'est ce qui fait du redresseur MAX(X,0) une fonction dérivable
  presque partout.

  Exemple :
     y = matlibre_dl_extremum('max', dlarray([-1 2]), 0, {});
     extractdata(y)     % 0 2

  Voir aussi DLARRAY, RELU.
```

## `matlibre_dl_format`

```
MATLIBRE_DL_FORMAT Format à donner au résultat d'une opération.
  F = MATLIBRE_DL_FORMAT(A,B) rend le format du premier opérande qui en
  porte un. Les étiquettes de dimension — 'S' pour spatiale, 'C' pour
  canal, 'B' pour observation, 'T' pour temps — se transmettent aux
  résultats des opérations qui ne changent pas la disposition.

  Exemple :
     matlibre_dl_format(dlarray(1, 'CB'), 2)     % CB

  Voir aussi DLARRAY, DIMS.
```

## `matlibre_dl_format_entree`

```
MATLIBRE_DL_FORMAT_ENTREE Format d'un lot, d'après son nombre de dimensions.
  F = MATLIBRE_DL_FORMAT_ENTREE(X) rend le format porté par X, ou celui
  qu'impose la convention : 'CB' pour une matrice, 'SCB' pour un
  tableau à trois dimensions, 'SSCB' pour un tableau à quatre.

  Exemple :
     matlibre_dl_format_entree(zeros(4, 8))      % CB

  Voir aussi DLARRAY, BATCHNORM, LAYERNORM.
```

## `matlibre_dl_gradients_de`

```
MATLIBRE_DL_GRADIENTS_DE Dérivée rendue sous la forme de la variable.
  G = MATLIBRE_DL_GRADIENTS_DE(VARIABLE,GRADIENTS) va chercher, dans le
  tableau des dérivées par nœud, celle qui revient à la variable — et
  rend la même forme qu'elle : un DLARRAY, un tableau de cellules ou
  une structure. Une variable dont la perte ne dépend pas reçoit une
  dérivée nulle plutôt qu'un tableau vide, ce qui laisse les solveurs
  travailler sans cas particulier.

  Exemple :
     g = matlibre_dl_gradients_de(dlarray(1), {[]});

  Voir aussi DLGRADIENT.
```

## `matlibre_dl_indices_classes`

```
MATLIBRE_DL_INDICES_CLASSES Numéro de classe de chaque étiquette.
  [I,C] = MATLIBRE_DL_INDICES_CLASSES(E,C) rend le numéro de la classe
  de chaque étiquette et la liste des classes. Une liste imposée est
  respectée, y compris son ordre ; sinon les classes sont celles que
  portent les étiquettes.

  Exemple :
     [i, c] = matlibre_dl_indices_classes({'b','a'}, {});
     i      % 2 1

  Voir aussi ONEHOTENCODE, ONEHOTDECODE.
```

## `matlibre_dl_indices_patchs`

```
MATLIBRE_DL_INDICES_PATCHS Positions lues par un filtre glissant.
  [I,T] = MATLIBRE_DL_INDICES_PATCHS(TAILLE,NOYAU,PAS,DILATATION) rend
  la matrice des numéros linéaires que le filtre lit : une ligne par
  coefficient du filtre — canal compris —, une colonne par position de
  sortie. T donne la taille spatiale de la sortie.

  Écrire la convolution comme un produit de matrices à partir de ces
  numéros a deux vertus : le calcul se ramène à une seule multiplication,
  et sa dérivée s'obtient en renvoyant les contributions à ces mêmes
  numéros, ce qui traite d'un coup le pas, le remplissage et la
  dilatation.

  Exemple :
     [i, t] = matlibre_dl_indices_patchs([3 3 1], [2 2], [1 1], [1 1]);
     size(i)     % 4 4

  Voir aussi DLCONV, MATLIBRE_DL_CONVOLUER.
```

## `matlibre_dl_moyenne_sur`

```
MATLIBRE_DL_MOYENNE_SUR Moyenne sur plusieurs dimensions à la fois.
  M = MATLIBRE_DL_MOYENNE_SUR(X,DIMENSIONS) réduit successivement les
  dimensions données ; celles-ci restent présentes, de taille un, ce qui
  permet de retrancher M de X par diffusion.

  Exemple :
     size(matlibre_dl_moyenne_sur(zeros(4, 5, 6), [1 3]))     % 1 5 1

  Voir aussi BATCHNORM, LAYERNORM, GROUPNORM.
```

## `matlibre_dl_noeud`

```
MATLIBRE_DL_NOEUD Numéro de nœud d'un opérande sur la bande.
  N = MATLIBRE_DL_NOEUD(X) rend le nœud que X occupe, ou zéro si X est
  une constante — un tableau ordinaire, ou un DLARRAY créé hors
  enregistrement. Un parent de numéro zéro ne reçoit pas de dérivée.

  Exemple :
     matlibre_dl_noeud(3)     % 0

  Voir aussi DLARRAY, MATLIBRE_BANDE, DLGRADIENT.
```

## `matlibre_dl_nombre_observations`

```
MATLIBRE_DL_NOMBRE_OBSERVATIONS Effectif d'un tableau de données.
  N = MATLIBRE_DL_NOMBRE_OBSERVATIONS(D) rend la taille de la dernière
  dimension, où se rangent les observations par convention.

  Exemple :
     matlibre_dl_nombre_observations(zeros(8, 8, 1, 30))      % 30

  Voir aussi MINIBATCHQUEUE.
```

## `matlibre_dl_normaliser`

```
MATLIBRE_DL_NORMALISER Centre et réduit sur les dimensions données.
  [Y,M,V] = MATLIBRE_DL_NORMALISER(X,DIMENSIONS,DECALAGE,ECHELLE,EPSILON)
  retranche la moyenne, divise par l'écart type, puis applique l'échelle
  et le décalage appris. C'est le calcul commun à la normalisation par
  lot, par couche et par groupe : seules changent les dimensions sur
  lesquelles la moyenne est prise.

  La variance est la variance de population — divisée par l'effectif, non
  par l'effectif moins un : c'est celle qui rend la sortie exactement
  centrée réduite sur les données vues.

  Tout est écrit avec des opérations dérivables : la dérivée du
  normaliseur, qui est fastidieuse à écrire à la main, s'obtient d'elle-même.

  Exemple :
     y = matlibre_dl_normaliser([1 2 3], 2, 0, 1, 0);
     mean(y)      % 0

  Voir aussi BATCHNORM, LAYERNORM, GROUPNORM.
```

## `matlibre_dl_options_perte`

```
MATLIBRE_DL_OPTIONS_PERTE Réglages communs aux fonctions de perte.
  [R,F,FORMAT] = MATLIBRE_DL_OPTIONS_PERTE(Y,ARGUMENTS) lit
  'Reduction', 'NormalizationFactor' et 'DataFormat'.

  Exemple :
     [r, f] = matlibre_dl_options_perte(1, {'Reduction', 'none'});

  Voir aussi L1LOSS, L2LOSS, HUBER.
```

## `matlibre_dl_position_lot`

```
MATLIBRE_DL_POSITION_LOT Dimension qui porte les observations.
  P = MATLIBRE_DL_POSITION_LOT(FORMAT,DIMENSIONS) rend la position de
  l'étiquette 'B' dans le format, ou la dernière dimension quand aucun
  format n'est donné — c'est là que se rangent les observations par
  convention.

  Exemple :
     matlibre_dl_position_lot('SSCB', 4)     % 4
     matlibre_dl_position_lot('', 3)         % 3

  Voir aussi FULLYCONNECT, DLARRAY.
```

## `matlibre_dl_reduire_perte`

```
MATLIBRE_DL_REDUIRE_PERTE Cumule et normalise les termes d'une perte.
  P = MATLIBRE_DL_REDUIRE_PERTE(TERMES,REDUCTION,FACTEUR,FORMAT) somme
  les termes puis divise selon le facteur demandé, ou les rend tels
  quels si REDUCTION vaut 'none'.

  Exemple :
     matlibre_dl_reduire_perte([1 3], 'sum', 'batch-size', 'CB')     % 2

  Voir aussi L1LOSS, L2LOSS, HUBER.
```

## `matlibre_dl_remplissage`

```
MATLIBRE_DL_REMPLISSAGE Épaisseur de zéros à ajouter autour de l'entrée.
  B = MATLIBRE_DL_REMPLISSAGE(SPEC,TAILLE,NOYAU,PAS,DILATATION) rend
  [haut bas gauche droite]. SPEC vaut un nombre, un couple, une matrice
  deux par deux, ou 'same' — qui calcule l'épaisseur telle que la sortie
  ait la taille de l'entrée divisée par le pas.

  Exemple :
     matlibre_dl_remplissage('same', [5 5], [3 3], [1 1], [1 1])   % 1 1 1 1

  Voir aussi DLCONV.
```

## `matlibre_dl_repetitions`

```
MATLIBRE_DL_REPETITIONS Nombre de copies demandé à REPMAT.
  R = MATLIBRE_DL_REPETITIONS(ARGUMENTS) accepte un vecteur, un nombre
  — qui vaut alors pour les deux premières dimensions — ou une suite de
  nombres, et rend le vecteur de répétitions.

  Exemple :
     matlibre_dl_repetitions({2})        % 2 2
     matlibre_dl_repetitions({2, 3})     % 2 3

  Voir aussi DLARRAY, REPMAT.
```

## `matlibre_dl_soustraire`

```
MATLIBRE_DL_SOUSTRAIRE Retranche un pas à un paramètre, sans l'enregistrer.
  P = MATLIBRE_DL_SOUSTRAIRE(P,AVANCE) rend le paramètre mis à jour. La
  mise à jour d'un solveur ne doit pas s'inscrire sur la bande : elle a
  lieu entre deux dérivations, pas à l'intérieur d'une.

  Exemple :
     p = matlibre_dl_soustraire(dlarray(1), 0.25);
     extractdata(p)      % 0.75

  Voir aussi ADAMUPDATE, SGDMUPDATE, RMSPROPUPDATE.
```

## `matlibre_dl_tracer`

```
MATLIBRE_DL_TRACER Fait de chaque DLARRAY une feuille de la bande.
  Y = MATLIBRE_DL_TRACER(X) recrée les DLARRAY que X contient en les
  rattachant à la bande qui vient d'être ouverte. X peut être un
  DLARRAY, un tableau de cellules, une structure ou un tableau de
  structures : les paramètres d'un réseau se rangent ainsi, et il faut
  que chacun soit dérivable.

  Exemple :
     matlibre_bande('ouvrir');
     p = matlibre_dl_tracer(struct('W', dlarray(1)));
     matlibre_bande('fermer');

  Voir aussi DLFEVAL, DLGRADIENT.
```

## `matlibre_dl_unaire`

```
MATLIBRE_DL_UNAIRE Enregistre une opération à un seul opérande.
  Y = MATLIBRE_DL_UNAIRE(OPERATION,A,VALEUR,DONNEES) fabrique le
  DLARRAY qui porte VALEUR et inscrit le nœud qui le relie à A.
  MATLIBRE_DL_UNAIRE(...,FORMAT) impose le format du résultat, pour les
  opérations qui changent la disposition des dimensions.

  Exemple :
     y = matlibre_dl_unaire('exp', dlarray(0), 1, {1});

  Voir aussi DLARRAY, MATLIBRE_BANDE, MATLIBRE_GRADIENT_OPERATION.
```

## `matlibre_dl_valeur`

```
MATLIBRE_DL_VALEUR Contenu numérique d'un opérande.
  V = MATLIBRE_DL_VALEUR(X) rend le tableau que X porte, que X soit un
  DLARRAY ou un tableau ordinaire. Les opérations mélangent librement
  les deux : un poids suivi peut être multiplié par une constante.

  Exemple :
     matlibre_dl_valeur(dlarray([1 2]))     % 1 2

  Voir aussi DLARRAY, EXTRACTDATA.
```

## `matlibre_dl_zeros_comme`

```
MATLIBRE_DL_ZEROS_COMME Conteneur de mêmes formes, rempli de zéros.
  Z = MATLIBRE_DL_ZEROS_COMME(C) sert à démarrer l'état d'un solveur :
  les moyennes glissantes partent de zéro, avec exactement la forme des
  paramètres qu'elles suivront.

  Exemple :
     z = matlibre_dl_zeros_comme({[1 2], 3});
     z{1}      % 0 0

  Voir aussi ADAMUPDATE, SGDMUPDATE, RMSPROPUPDATE.
```

## `matlibre_glorot`

```
MATLIBRE_GLOROT Tirage initial des poids d'une couche.
  W = MATLIBRE_GLOROT(TAILLE,ENTREES,SORTIES) tire uniformément dans
  l'intervalle de demi-largeur racine de six sur la somme du nombre
  d'entrées et de sorties.

  Ce choix conserve la variance du signal en traversant la couche, dans
  les deux sens : sans lui, les activations d'un réseau profond enflent
  ou s'éteignent d'une couche à l'autre, et le gradient avec elles.

  Exemple :
     W = matlibre_glorot([3 4], 4, 3);
     max(abs(W(:))) <= sqrt(6 / 7)      % vrai

  Voir aussi MATLIBRE_COUCHE_INITIALISER, DLNETWORK.
```

## `matlibre_gradient_agregation`

```
MATLIBRE_GRADIENT_AGREGATION Dérivée d'une agrégation.
  C = MATLIBRE_GRADIENT_AGREGATION(G,DONNEES) rend la dérivée par
  rapport à l'entrée. Pour le maximum, elle ne revient qu'à l'élément
  qui a gagné sa fenêtre ; pour la moyenne, elle se partage à parts
  égales entre tous les éléments de la fenêtre.

  Un même pixel appartenant à plusieurs fenêtres quand elles se
  recouvrent, les contributions s'y ajoutent.

  Exemple :
     % appelée par la rétropropagation, jamais directement

  Voir aussi MAXPOOL, AVGPOOL, MATLIBRE_DL_AGREGER.
```

## `matlibre_gradient_convolution`

```
MATLIBRE_GRADIENT_CONVOLUTION Dérivées d'une convolution.
  C = MATLIBRE_GRADIENT_CONVOLUTION(G,DONNEES) rend les dérivées par
  rapport à l'entrée, aux poids et au biais.

  La convolution ayant été écrite comme un produit de matrices, ses
  dérivées sont celles d'un produit : la dérivée des poids est le
  produit de la dérivée de sortie par les voisinages lus, et celle de
  l'entrée se redistribue aux positions d'où les voisinages venaient —
  chaque pixel recevant la somme de ce que toutes les positions qui
  l'ont lu lui rendent.

  Exemple :
     % appelée par la rétropropagation, jamais directement

  Voir aussi DLCONV, MATLIBRE_DL_CONVOLUER, DLGRADIENT.
```

## `matlibre_gradient_operation`

```
MATLIBRE_GRADIENT_OPERATION Dérivée d'une opération, remontée aux parents.
  C = MATLIBRE_GRADIENT_OPERATION(NOEUD,G) rend, pour chaque parent du
  nœud, la part de dérivée qui lui revient, sachant que la dérivée du
  résultat est G. C'est la règle de dérivation en chaîne, écrite une
  fois par opération.

  Là où une opération a diffusé un opérande pour l'apparier à l'autre,
  la dérivée est resommée sur les dimensions étirées : chaque copie a
  reçu sa part, l'opérande d'origine reçoit leur somme.

  Exemple :
     n.operation = 'exp'; n.parents = 1; n.donnees = {exp(2)};
     c = matlibre_gradient_operation(n, 1);
     c{1}      % exp(2)

  Voir aussi DLGRADIENT, MATLIBRE_BANDE.
```

## `matlibre_reduire_gradient`

```
MATLIBRE_REDUIRE_GRADIENT Ramène un gradient à la taille de l'opérande.
  G = MATLIBRE_REDUIRE_GRADIENT(G,TAILLE) somme le gradient sur les
  dimensions que la diffusion implicite avait étirées. Quand une
  opération répète un opérande pour l'apparier à l'autre, chaque copie
  reçoit sa part de dérivée, et la dérivée de l'opérande d'origine est
  la somme de ces parts.

  Exemple :
     matlibre_reduire_gradient(ones(3, 4), [3 1])     % des 4, en 3 par 1

  Voir aussi DLGRADIENT, DLARRAY.
```

## `matlibre_reseau_activation`

```
MATLIBRE_RESEAU_ACTIVATION Sortie d'une couche nommée.
  Y = MATLIBRE_RESEAU_ACTIVATION(RESEAU,X,COUCHE) applique le réseau
  jusqu'à la couche demandée et rend ce qu'elle produit.

  Exemple :
     y = activations(net, X, 'relu_1');

  Voir aussi DLNETWORK, ACTIVATIONS.
```

## `matlibre_reseau_avant`

```
MATLIBRE_RESEAU_AVANT Passage avant d'un réseau, couche par couche.
  [S,ETAT] = MATLIBRE_RESEAU_AVANT(RESEAU,ENTREES,APPRENTISSAGE)
  parcourt le graphe dans l'ordre du calcul, applique chaque couche aux
  sorties de celles qui l'alimentent, et rend les sorties du réseau
  ainsi que l'état mis à jour.

  ENTREES est un tableau de cellules, une donnée par couche d'entrée.

  Toutes les opérations passent par DLARRAY : le passage est donc
  dérivable de bout en bout, y compris à travers les branches et les
  couches récurrentes.

  Exemple :
     s = matlibre_reseau_avant(net, {dlarray(randn(3, 5), 'CB')}, false);

  Voir aussi DLNETWORK, FORWARD, PREDICT.
```

## `matlibre_reseau_bornes`

```
MATLIBRE_RESEAU_BORNES Couches d'entrée et de sortie d'un réseau.
  [E,S] = MATLIBRE_RESEAU_BORNES(RESEAU) rend le nom des couches que
  rien n'alimente et celui des couches qui n'alimentent rien.

  Exemple :
     net = dlnetwork({featureInputLayer(2), softmaxLayer()});
     net.InputNames{1}

  Voir aussi DLNETWORK, LAYERGRAPH.
```

## `matlibre_reseau_connexions_vides`

```
MATLIBRE_RESEAU_CONNEXIONS_VIDES Table de connexions sans aucune arête.
  T = MATLIBRE_RESEAU_CONNEXIONS_VIDES() rend la table à deux colonnes,
  source et destination, que porte un graphe de couches.

  Exemple :
     height(matlibre_reseau_connexions_vides())      % 0

  Voir aussi LAYERGRAPH, DLNETWORK.
```

## `matlibre_reseau_ecrire`

```
MATLIBRE_RESEAU_ECRIRE Range les paramètres d'une couche dans la table.
  T = MATLIBRE_RESEAU_ECRIRE(T,NOM,VALEURS) remplace les lignes de la
  couche nommée par les champs de la structure VALEURS, ou les ajoute si
  elles n'y sont pas.

  Exemple :
     t = matlibre_reseau_ecrire(t, 'bn_1', struct('TrainedMean', 0));

  Voir aussi DLNETWORK, MATLIBRE_RESEAU_LIRE.
```

## `matlibre_reseau_initialiser`

```
MATLIBRE_RESEAU_INITIALISER Tire les poids de toutes les couches.
  RESEAU = MATLIBRE_RESEAU_INITIALISER(RESEAU,EXEMPLES) parcourt le
  graphe dans l'ordre du calcul, propage les tailles de couche en
  couche, et tire les poids de chacune dès que la taille de ce qui
  l'alimente est connue.

  EXEMPLES est un tableau de cellules de données, une par couche
  d'entrée ; il est facultatif quand les couches d'entrée déclarent leur
  taille. Une taille qu'on ne peut pas déduire laisse le réseau non
  initialisé plutôt que d'échouer : c'est INITIALIZE, plus tard, qui
  finira le travail.

  Exemple :
     net = dlnetwork({featureInputLayer(3), fullyConnectedLayer(2)});
     net.Initialized      % vrai

  Voir aussi DLNETWORK, INITIALIZE.
```

## `matlibre_reseau_lire`

```
MATLIBRE_RESEAU_LIRE Paramètres d'une couche, en structure.
  V = MATLIBRE_RESEAU_LIRE(TABLEAU,NOM) extrait de la table des
  paramètres ceux de la couche nommée, sous la forme d'une structure
  dont les champs portent le nom du paramètre.

  Exemple :
     v = matlibre_reseau_lire(net.Learnables, 'fc_1');
     size(v.Weights)

  Voir aussi DLNETWORK, MATLIBRE_RESEAU_ECRIRE.
```

## `matlibre_reseau_nom_libre`

```
MATLIBRE_RESEAU_NOM_LIBRE Nom automatique pour une couche anonyme.
  N = MATLIBRE_RESEAU_NOM_LIBRE(PRIS,TYPE) rend le type suivi du plus
  petit numéro qui ne soit pas déjà pris, comme le fait MATLAB.

  Exemple :
     matlibre_reseau_nom_libre({'relu_1'}, 'relu')     % relu_2

  Voir aussi ADDLAYERS, LAYERGRAPH.
```

## `matlibre_reseau_nom_seul`

```
MATLIBRE_RESEAU_NOM_SEUL Nom de couche, sans le nom du port.
  N = MATLIBRE_RESEAU_NOM_SEUL('somme/in2') rend 'somme'. MATLAB nomme
  les ports d'entrée d'une couche qui en a plusieurs ; MatLibre les
  raccorde dans l'ordre où on les pose, et ne retient donc que la
  couche.

  Exemple :
     matlibre_reseau_nom_seul('add/in2')     % add

  Voir aussi CONNECTLAYERS.
```

## `matlibre_reseau_ordre`

```
MATLIBRE_RESEAU_ORDRE Ordre de calcul des couches d'un graphe.
  O = MATLIBRE_RESEAU_ORDRE(NOMS,CONNEXIONS) rend les indices des
  couches dans un ordre où chacune vient après tout ce qui l'alimente.
  C'est le tri topologique : il existe si et seulement si le graphe n'a
  pas de cycle, ce qui est la condition pour qu'un passage avant ait un
  sens.

  Exemple :
     lg = layerGraph({reluLayer(), reluLayer()});
     matlibre_reseau_ordre(lg.Names, lg.Connections)     % 1 2

  Voir aussi DLNETWORK, LAYERGRAPH.
```

## `matlibre_reseau_sorties`

```
MATLIBRE_RESEAU_SORTIES Arguments de sortie d'un passage avant.
  S = MATLIBRE_RESEAU_SORTIES(SORTIES,ETAT,NOMBRE) rend les sorties
  demandées, suivies de l'état quand le réseau n'a qu'une sortie et
  qu'on en demande deux — c'est la convention de MATLAB.

  Exemple :
     s = matlibre_reseau_sorties({1}, [], 2);

  Voir aussi DLNETWORK, FORWARD, PREDICT.
```

## `matlibre_reseau_sources`

```
MATLIBRE_RESEAU_SOURCES Couches qui alimentent une couche donnée.
  S = MATLIBRE_RESEAU_SOURCES(RESEAU,NOM) rend, dans l'ordre où elles
  ont été raccordées, le nom des couches dont la sortie entre dans la
  couche nommée. L'ordre compte pour une concaténation.

  Exemple :
     net = dlnetwork({featureInputLayer(2), reluLayer()});
     matlibre_reseau_sources(net, net.Names{2})

  Voir aussi DLNETWORK, CONNECTLAYERS.
```

## `matlibre_reseau_table_vide`

```
MATLIBRE_RESEAU_TABLE_VIDE Table de paramètres sans aucune ligne.
  T = MATLIBRE_RESEAU_TABLE_VIDE() rend la table à trois colonnes —
  couche, paramètre, valeur — que portent les propriétés Learnables et
  State d'un DLNETWORK.

  Exemple :
     height(matlibre_reseau_table_vide())      % 0

  Voir aussi DLNETWORK.
```

## `matlibre_retropropager`

```
MATLIBRE_RETROPROPAGER Remonte la bande et accumule les dérivées.
  G = MATLIBRE_RETROPROPAGER(SORTIE) rend un tableau de cellules qui
  donne, pour chaque nœud de la bande, la dérivée du nœud SORTIE par
  rapport à lui.

  Les nœuds ayant été inscrits dans l'ordre du calcul, les parcourir en
  sens inverse suffit : quand on arrive à un nœud, toutes les
  contributions qui lui reviennent ont déjà été ajoutées.

  Exemple :
     matlibre_bande('ouvrir');
     x = dlarray(3);
     y = x * x;
     g = matlibre_retropropager(y.Noeud);
     g{x.Noeud}      % 6

  Voir aussi DLGRADIENT, MATLIBRE_GRADIENT_OPERATION.
```

## `matlibre_taille_glissante`

```
MATLIBRE_TAILLE_GLISSANTE Taille produite par un filtre glissant.
  T = MATLIBRE_TAILLE_GLISSANTE(ENTREE,NOYAU,PAS,BORDS,DILATATION) rend
  le nombre de positions que prend le filtre dans chaque dimension.

  Exemple :
     matlibre_taille_glissante([5 5], [3 3], [1 1], [0 0 0 0], [1 1])   % 3 3

  Voir aussi DLCONV, MAXPOOL, MATLIBRE_COUCHE_INITIALISER.
```

## `maxPooling1dLayer`

```
MAXPOOLING1DLAYER Agrégation par le maximum, en une dimension.
  C = MAXPOOLING1DLAYER(T) ne garde de chaque fenêtre de T positions que
  la plus grande valeur. La sortie ne change pas quand le motif se
  déplace de moins d'une fenêtre.

  Options : 'Stride' (la taille de la fenêtre), 'Padding' (0 ou 'same').

  Exemple :
     c = maxPooling1dLayer(3, 'Stride', 1);

  Voir aussi AVERAGEPOOLING1DLAYER, MAXPOOLING2DLAYER, MAXPOOL.
```

## `maxPooling2dLayer`

```
MAXPOOLING2DLAYER Sous-échantillonnage par le maximum.
  C = MAXPOOLING2DLAYER(TAILLE) ; le pas vaut la taille par défaut,
  comme dans MATLAB. Option : 'Stride'.
```

## `maxpool`

```
MAXPOOL Agrégation par le maximum.
  Y = MAXPOOL(X,FENETRE) ne garde, de chaque fenêtre, que la plus grande
  valeur. La sortie est plus petite, et surtout elle ne change pas quand
  le motif se déplace de moins d'une fenêtre : c'est ce qui donne à un
  réseau convolutif sa tolérance aux petits décalages.

  [Y,I,T] = MAXPOOL(...) rend aussi les positions retenues et la taille
  de l'entrée, de quoi défaire l'agrégation.

  Options et valeurs par défaut :
    'Stride'       la taille de la fenêtre
    'Padding'      0, ou 'same'
    'DataFormat'   le format, quand X n'en porte pas

  Le remplissage vaut moins l'infini : une case ajoutée ne peut pas
  l'emporter sur une vraie valeur.

  Exemple :
     extractdata(maxpool(dlarray(reshape(1:16, 4, 4), 'SS'), 2))

  Voir aussi AVGPOOL, MAXPOOLING2DLAYER, DLCONV.
```

## `minibatchqueue`

```
MINIBATCHQUEUE Découpe des données en lots successifs.
  MBQ = MINIBATCHQUEUE(X1,X2,...) range les données et les rend par
  lots. La dernière dimension de chaque tableau compte les observations,
  et tous doivent en avoir le même nombre.

  L'apprentissage d'un réseau ne présente pas tout le jeu de données à
  la fois : il avance par petits lots, ce qui tient en mémoire, donne
  plusieurs pas de descente par passage, et introduit un bruit qui aide
  à sortir des minimums étroits. Cet objet tient le compte des
  observations déjà servies et de l'ordre de tirage.

  Options et valeurs par défaut :
    'MiniBatchSize'      128
    'MiniBatchFormat'    le format à donner à chaque sortie, par exemple
                         {'CB','CB'} ; vide rend des tableaux ordinaires
    'PartialMiniBatch'   'return', ou 'discard' pour ignorer le dernier
                         lot quand il est incomplet

  Méthodes : HASDATA dit s'il reste des lots, NEXT rend le suivant,
  SHUFFLE retire l'ordre au hasard, RESET revient au début.

  MATLAB part d'un magasin de données ; MatLibre accepte directement les
  tableaux, ce qui revient au même pour des données qui tiennent en
  mémoire.

  Exemple :
     mbq = minibatchqueue(randn(3, 100), randn(2, 100), ...
                          'MiniBatchSize', 16, 'MiniBatchFormat', {'CB', ''});
     while hasdata(mbq)
         [X, T] = next(mbq);
     end

  Voir aussi DLNETWORK, DLFEVAL, ADAMUPDATE.
```

## `mse`

```
MSE Erreur quadratique moyenne.
```

## `multiplicationLayer`

```
MULTIPLICATIONLAYER Produit terme à terme de plusieurs entrées.
  C = MULTIPLICATIONLAYER(N) multiplie ses N entrées terme à terme.
  C'est la couche des portes d'attention : une entrée module l'autre.

  Exemple :
     c = multiplicationLayer(2, 'Name', 'porte');

  Voir aussi ADDITIONLAYER, CONCATENATIONLAYER, LAYERGRAPH.
```

## `onehotdecode`

```
ONEHOTDECODE Indicatrices ou probabilités en étiquettes.
  E = ONEHOTDECODE(A,CLASSES,DIM) rend, pour chaque observation, la
  classe de plus grande valeur. C'est l'opération inverse de
  ONEHOTENCODE, et c'est aussi ce qui transforme la sortie d'un
  classifieur en décision.

  E = ONEHOTDECODE(A,CLASSES,DIM,GENRE) où GENRE vaut 'categorical'
  (défaut), 'string', 'double' ou 'cell'.

  Exemple :
     onehotdecode([0.2 0.9; 0.8 0.1], {'a','b'}, 1)      % b, a

  Voir aussi ONEHOTENCODE, CLASSIFY, CATEGORICAL.
```

## `onehotencode`

```
ONEHOTENCODE Étiquettes en indicatrices.
  A = ONEHOTENCODE(E,DIM) rend, pour chaque étiquette, un vecteur nul
  sauf un un à la position de sa classe. DIM dit selon quelle dimension
  ranger les classes : un pour une colonne par observation, deux pour
  une ligne.

  E peut être un tableau catégoriel, un tableau de cellules de chaînes,
  ou un vecteur d'entiers. Les classes sont prises dans l'ordre de
  CATEGORIES, c'est-à-dire l'ordre alphabétique pour des chaînes.

  ONEHOTENCODE(...,'ClassNames',C) impose la liste des classes et leur
  ordre — nécessaire dès qu'un lot ne les contient pas toutes.

  Un classifieur ne prédit pas une étiquette mais une loi sur les
  classes ; c'est cette forme-là qu'il faut lui donner comme cible.

  Exemple :
     onehotencode({'a','b','a'}, 1)

  Voir aussi ONEHOTDECODE, CATEGORICAL, CROSSENTROPY.
```

## `predictReseau`

```
PREDICTRESEAU Sortie d'un réseau appris.
  C'est le rouage qu'appelle PREDICT quand on lui donne un réseau ;
  PREDICT est le nom commun à tous les modèles, comme dans MATLAB.
  Les couches qui se comportent autrement à l'apprentissage — abandon,
  normalisation par lot — sont ici en mode prédiction.

  Pour un réseau à couches spatiales, X est un tableau H x L x P x N ;
  la sortie reste une matrice, une colonne par observation.
```

## `regressionLayer`

```
REGRESSIONLAYER Couche de sortie pour la régression.
  Elle déclare que le coût est l'erreur quadratique moyenne.
```

## `relu`

```
RELU Redresseur linéaire : max(0,x).
```

## `reluLayer`

```
RELULAYER Couche de redressement : max(0,x).
```

## `rmspropupdate`

_Pas de bloc d'aide._

## `sequenceInputLayer`

```
SEQUENCEINPUTLAYER Entrée d'un réseau récurrent.
  C = SEQUENCEINPUTLAYER(T) déclare des séquences de T composantes par
  pas de temps. Les données se rangent en canaux-observations-temps :
  une matrice par observation, une colonne par instant.

  Option : 'Normalization' ('none' par défaut, ou 'zscore').

  Exemple :
     c = sequenceInputLayer(3);

  Voir aussi LSTMLAYER, GRULAYER, BILSTMLAYER, FEATUREINPUTLAYER.
```

## `sgdmupdate`

```
SGDMUPDATE Un pas de descente de gradient à inertie.
  [P,V] = SGDMUPDATE(P,G,V) retranche aux paramètres non pas le gradient
  seul mais une vitesse, qui garde une part du déplacement précédent.
  L'inertie traverse les creux étroits où le gradient seul oscillerait,
  et accumule de la vitesse dans les vallées longues.

  [P,V] = SGDMUPDATE(P,G,V,PAS,INERTIE) impose les réglages ; par
  défaut, 0,01 et 0,9.

  P, G et V peuvent être un DLARRAY, un tableau de cellules, une
  structure ou une table de paramètres.

  Exemple :
     [p, v] = sgdmupdate(dlarray(1), dlarray(2), []);
     extractdata(p)      % 0.98

  Voir aussi ADAMUPDATE, RMSPROPUPDATE, TRAININGOPTIONS.
```

## `sigmoid`

```
SIGMOID Sigmoïde logistique 1/(1+exp(-x)).
```

## `sigmoidLayer`

```
SIGMOIDLAYER Couche sigmoïde logistique.
```

## `softmax`

```
SOFTMAX Normalisation exponentielle, colonne par colonne.
  Y = SOFTMAX(X) rend, pour chaque colonne, les exponentielles
  normalisées à somme un : c'est la sortie d'un classifieur, lue comme
  une loi de probabilité sur les classes.

  Le maximum de la colonne est retranché avant l'exponentielle. Cela ne
  change rien au résultat — le facteur commun se simplifie — mais
  empêche le débordement dès que les scores dépassent quelques
  centaines.

  X peut être un DLARRAY : l'opération est alors dérivable, et sa
  dérivée s'obtient sans qu'on ait à l'écrire.

  Exemple :
     softmax([0; log(3)])      % 0.25 ; 0.75

  Voir aussi SIGMOID, RELU, CROSSENTROPY, SOFTMAXLAYER.
```

## `softmaxLayer`

```
SOFTMAXLAYER Couche softmax : sorties positives de somme 1.
```

## `softplusLayer`

```
SOFTPLUSLAYER Redresseur adouci, log(1+exp(X)).
  C = SOFTPLUSLAYER() rend une sortie toujours positive et dérivable
  partout — sa dérivée est la sigmoïde. On l'emploie là où une sortie
  doit rester positive, un écart type par exemple.

  Exemple :
     c = softplusLayer();

  Voir aussi RELULAYER, GELULAYER, SWISHLAYER.
```

## `swishLayer`

```
SWISHLAYER Activation X fois sigmoïde de X.
  C = SWISHLAYER() applique X./(1+exp(-X)). Comme la gaussienne à
  porte, elle est lisse et laisse passer un peu de négatif, ce qui
  entretient le gradient là où le redresseur l'annule.

  Exemple :
     c = swishLayer();

  Voir aussi GELULAYER, RELULAYER, SOFTPLUSLAYER.
```

## `tanhLayer`

```
TANHLAYER Couche à tangente hyperbolique.
```

## `trainNetwork`

```
TRAINNETWORK Apprentissage d'un réseau par rétropropagation.
  RESEAU = TRAINNETWORK(X,Y,COUCHES,OPTIONS) apprend à associer les
  colonnes de X (une observation par colonne) aux colonnes de Y.

  Si le réseau contient des couches spatiales — IMAGEINPUTLAYER,
  CONVOLUTION2DLAYER, MAXPOOLING2DLAYER, AVERAGEPOOLING2DLAYER,
  FLATTENLAYER — alors X est un tableau H x L x P x N : une image par
  tranche, comme dans MATLAB. Y reste une matrice, une colonne par
  observation.

  Le coût est l'entropie croisée si la dernière couche est un softmax,
  l'erreur quadratique sinon. La descente est stochastique avec inertie.

  Exemple :
     couches = {imageInputLayer([8 8 1]), convolution2dLayer(3, 4), ...
                reluLayer(), maxPooling2dLayer(2), flattenLayer(), ...
                fullyConnectedLayer(2), softmaxLayer()};
     reseau = trainNetwork(images, etiquettes, couches, options);
```

## `trainingOptions`

```
TRAININGOPTIONS Réglages de l'apprentissage.
  OPT = TRAININGOPTIONS('sgdm','MaxEpochs',N,'InitialLearnRate',R, ...
                        'MiniBatchSize',B,'Momentum',M,'Verbose',V)
```

## `transposedConv2dLayer`

```
TRANSPOSEDCONV2DLAYER Convolution transposée, qui agrandit l'image.
  C = TRANSPOSEDCONV2DLAYER(TAILLE,FILTRES) fait le chemin inverse d'une
  convolution : là où celle-ci résume un voisinage en un point, celle-ci
  étale un point sur un voisinage. Avec un pas de deux, elle double la
  taille de l'image — c'est la couche qui remonte l'échelle dans les
  réseaux de segmentation et les générateurs.

  Options et valeurs par défaut :
    'Stride'    1, le facteur d'agrandissement
    'Cropping'  0, ce qu'on retire des bords après coup, ou 'same'

  Exemple :
     c = transposedConv2dLayer(4, 8, 'Stride', 2, 'Cropping', 1);

  Voir aussi CONVOLUTION2DLAYER, DLCONV.
```

