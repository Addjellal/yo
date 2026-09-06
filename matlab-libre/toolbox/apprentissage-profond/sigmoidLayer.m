function couche = sigmoidLayer(varargin)
%SIGMOIDLAYER Couche sigmoïde logistique.
%   C = SIGMOIDLAYER() rend la couche qui applique 1/(1+exp(-x)) terme à
%   terme. C = SIGMOIDLAYER('Name',NOM) la nomme.
%
%   En sortie de réseau, elle sert à la classification multi-étiquette :
%   chaque sortie est une probabilité indépendante, et plusieurs peuvent
%   valoir 1 à la fois. C'est ce qui la distingue de SOFTMAXLAYER, dont
%   les sorties somment à un et s'excluent donc mutuellement.
%
%   Exemple :
%      couches = [featureInputLayer(3); fullyConnectedLayer(1); sigmoidLayer()];
%
%   Voir aussi SIGMOID, SOFTMAXLAYER, TANHLAYER.
    couche = struct('type', 'sigmoid', 'sorties', 0, 'W', [], 'b', [], ...
                    'entree', [], 'sortie', [], ...
                    'nom', matlibre_couche_nom(varargin));
end
