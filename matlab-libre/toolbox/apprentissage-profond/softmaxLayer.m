function couche = softmaxLayer(varargin)
%SOFTMAXLAYER Couche softmax : sorties positives de somme 1.
%   C = SOFTMAXLAYER() rend la couche qui exponentie ses entrées puis les
%   normalise : les sorties sont positives et somment à un.
%   C = SOFTMAXLAYER('Name',NOM) la nomme.
%
%   Seuls les écarts entre entrées comptent : ajouter une constante à
%   toutes les entrées laisse la sortie inchangée. C'est cette invariance
%   qui permet de retrancher le maximum avant d'exponentier, et donc de
%   calculer la couche sans débordement même sur de grandes entrées.
%
%   Ses sorties s'excluent : monter la probabilité d'une classe abaisse
%   nécessairement celles des autres. Elle va donc avec une décision
%   à une classe parmi N, et se place juste avant l'entropie croisée.
%
%   Exemple :
%      couches = [featureInputLayer(4); fullyConnectedLayer(3); softmaxLayer()];
%
%   Voir aussi SOFTMAX, SIGMOIDLAYER, CROSSENTROPY, CLASSIFY.
    couche = struct('type', 'softmax', 'sorties', 0, 'W', [], 'b', [], ...
                    'entree', [], 'sortie', [], ...
                    'nom', matlibre_couche_nom(varargin));
end
