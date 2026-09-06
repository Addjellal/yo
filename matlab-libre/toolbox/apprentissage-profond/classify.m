function [classes, scores] = classify(reseau, X)
%CLASSIFY Classe de plus forte probabilité pour chaque observation.
%   C = CLASSIFY(RESEAU,X) rend, pour chaque observation de X, l'indice de
%   la classe de plus fort score. C est une colonne, une entrée par
%   observation.
%
%   [C,SCORES] = CLASSIFY(RESEAU,X) rend en plus les scores complets, une
%   colonne par observation. Il faut les regarder : l'indice seul ne
%   distingue pas une réponse à 0,99 d'une réponse à 0,34 contre 0,33 et
%   0,33, alors que la première est une décision et la seconde un tirage
%   au sort. Un seuil sur le score maximal permet de refuser de conclure.
%
%   RESEAU est un réseau appris par TRAINNETWORK.
%
%   Exemple :
%      X = [randn(2, 30), randn(2, 30) + 3];
%      Y = [repmat([1; 0], 1, 30), repmat([0; 1], 1, 30)];
%      couches = {fullyConnectedLayer(4), reluLayer(), ...
%                 fullyConnectedLayer(2), softmaxLayer()};
%      reseau = trainNetwork(X, Y, couches, trainingOptions('sgdm'));
%      [c, s] = classify(reseau, X);
%
%   Voir aussi PREDICTRESEAU, SOFTMAXLAYER, CONFUSIONCHART.
    scores = predict(reseau, X);
    [~, classes] = max(scores, [], 1);
    classes = classes(:);
end
