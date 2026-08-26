# Toolbox `apprentissage-profond`

```
% Deep Learning Toolbox — réseaux de neurones.
%
% Un réseau est un tableau de cellules de couches ; chaque couche est une
% structure portant son type, ses poids et ses biais. L'apprentissage se
% fait par rétropropagation du gradient et descente stochastique.
%
%   fullyConnectedLayer - Couche entièrement connectée
%   reluLayer           - Redresseur max(0,x)
%   sigmoidLayer        - Sigmoïde logistique
%   tanhLayer           - Tangente hyperbolique
%   softmaxLayer        - Normalisation exponentielle
%   trainingOptions     - Réglages de l'apprentissage
%   trainNetwork        - Apprentissage par rétropropagation
%   predict             - Sortie du réseau
%   classify            - Classe prédite
%   crossentropy, mse   - Fonctions de coût
%   sigmoid, relu, softmax - Fonctions d'activation
%
% Couches supplémentaires
%   leakyReluLayer, eluLayer     - Activations à fuite et exponentielle
%   dropoutLayer                 - Abandon, à l'apprentissage seulement
%   batchNormalizationLayer      - Normalisation par lot, avec moyennes
%                                  glissantes pour la prédiction
%   featureInputLayer            - Entrée de caractéristiques
%   classificationLayer          - Déclare le coût d'entropie croisée
%   regressionLayer              - Déclare le coût quadratique
%
% Couches spatiales — réseaux convolutifs
%   imageInputLayer              - Entrée H x L x P, un tableau
%                                  H x L x P x N à l'apprentissage
%   convolution2dLayer           - Convolution 2-D, options 'Stride' et
%                                  'Padding' (entier ou 'same')
%   maxPooling2dLayer            - Agrégation par le maximum
%   averagePooling2dLayer        - Agrégation par la moyenne
%   flattenLayer                 - Passage des images aux vecteurs
%   couchesConvolution           - Propagation avant et arrière de ces
%                                  couches (appelée par TRAINNETWORK)
```

## `averagePooling2dLayer`

```
AVERAGEPOOLING2DLAYER Sous-échantillonnage par la moyenne.
```

## `batchNormalizationLayer`

```
BATCHNORMALIZATIONLAYER Normalisation par lot.
  Centre et réduit chaque composante sur le lot, puis applique un gain
  et un décalage appris. Les moyennes glissantes servent à la
  prédiction.
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

## `crossentropy`

```
CROSSENTROPY Entropie croisée moyenne par observation.
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

## `leakyReluLayer`

```
LEAKYRELULAYER Couche ReLU à fuite : pente non nulle pour les négatifs.
  C = LEAKYRELULAYER(PENTE) ; PENTE vaut 0,01 par défaut.
```

## `maxPooling2dLayer`

```
MAXPOOLING2DLAYER Sous-échantillonnage par le maximum.
  C = MAXPOOLING2DLAYER(TAILLE) ; le pas vaut la taille par défaut,
  comme dans MATLAB. Option : 'Stride'.
```

## `mse`

```
MSE Erreur quadratique moyenne.
```

## `predict`

```
PREDICT Sortie d'un réseau appris.
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
```

## `softmaxLayer`

```
SOFTMAXLAYER Couche softmax : sorties positives de somme 1.
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

