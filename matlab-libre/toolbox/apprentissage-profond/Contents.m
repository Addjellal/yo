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
