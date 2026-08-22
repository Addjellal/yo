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
```

## `classify`

```
CLASSIFY Classe de plus forte probabilité pour chaque observation.
```

## `crossentropy`

```
CROSSENTROPY Entropie croisée moyenne par observation.
```

## `fullyConnectedLayer`

```
FULLYCONNECTEDLAYER Couche entièrement connectée de N sorties.
  Les poids sont initialisés par la règle de Glorot une fois la taille
  d'entrée connue, au premier appel de TRAINNETWORK.
```

## `mse`

```
MSE Erreur quadratique moyenne.
```

## `predict`

```
PREDICT Sortie d'un réseau appris.
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

