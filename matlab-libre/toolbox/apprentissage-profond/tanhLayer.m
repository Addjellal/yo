function couche = tanhLayer(varargin)
%TANHLAYER Couche à tangente hyperbolique.
%   C = TANHLAYER() rend la couche qui applique tanh terme à terme.
%   C = TANHLAYER('Name',NOM) la nomme.
%
%   La tangente hyperbolique est une sigmoïde redressée : tanh(x) vaut
%   2*sigmoid(2*x)-1, donc la même courbe portée sur ]-1,1[ et centrée en
%   zéro. Ce centrage est son intérêt — les activations transmises à la
%   couche suivante ont une moyenne proche de zéro, ce qui évite que tous
%   les gradients d'un même neurone partagent le même signe.
%
%   Elle sature comme la sigmoïde, et perd donc son gradient de la même
%   façon dans une pile profonde ; c'est dans les réseaux récurrents,
%   où la borne sur la sortie tient l'état, qu'elle reste employée.
%
%   Exemple :
%      couches = [featureInputLayer(3); fullyConnectedLayer(4); tanhLayer()];
%
%   Voir aussi RELULAYER, SIGMOIDLAYER, LSTMLAYER.
    couche = struct('type', 'tanh', 'sorties', 0, 'W', [], 'b', [], ...
                    'entree', [], 'sortie', [], ...
                    'nom', matlibre_couche_nom(varargin));
end
