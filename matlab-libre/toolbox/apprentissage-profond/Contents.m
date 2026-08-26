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
