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
