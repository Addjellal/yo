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
