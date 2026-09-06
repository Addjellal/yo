function couche = reluLayer(varargin)
%RELULAYER Couche de redressement : max(0,x).
%   C = RELULAYER() rend la couche qui applique max(0,x) terme à terme.
%   C = RELULAYER('Name',NOM) la nomme.
%
%   Elle n'a aucun paramètre à apprendre : son seul rôle est de rompre la
%   linéarité. Sans elle, empiler des couches pleinement connectées
%   reviendrait à une seule, puisque le produit de matrices est une
%   matrice.
%
%   Exemple :
%      couches = [featureInputLayer(3); fullyConnectedLayer(5); reluLayer()];
%
%   Voir aussi RELU, LEAKYRELULAYER, ELULAYER, TANHLAYER.
    couche = struct('type', 'relu', 'sorties', 0, 'W', [], 'b', [], ...
                    'entree', [], 'sortie', [], ...
                    'nom', matlibre_couche_nom(varargin));
end
