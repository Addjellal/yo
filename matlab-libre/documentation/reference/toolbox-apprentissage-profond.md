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

## `fullyConnectedLayer`

```
FULLYCONNECTEDLAYER Couche entièrement connectée de N sorties.
  Les poids sont initialisés par la règle de Glorot une fois la taille
  d'entrée connue, au premier appel de TRAINNETWORK.
```

## `leakyReluLayer`

```
LEAKYRELULAYER Couche ReLU à fuite : pente non nulle pour les négatifs.
  C = LEAKYRELULAYER(PENTE) ; PENTE vaut 0,01 par défaut.
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

  Le coût est l'entropie croisée si la dernière couche est un softmax,
  l'erreur quadratique sinon. La descente est stochastique avec inertie.
```

## `trainingOptions`

```
TRAININGOPTIONS Réglages de l'apprentissage.
  OPT = TRAININGOPTIONS('sgdm','MaxEpochs',N,'InitialLearnRate',R, ...
                        'MiniBatchSize',B,'Momentum',M,'Verbose',V)
```

