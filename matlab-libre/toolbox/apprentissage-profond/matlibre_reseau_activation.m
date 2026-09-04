function y = matlibre_reseau_activation(reseau, X, couche)
%MATLIBRE_RESEAU_ACTIVATION Sortie d'une couche nommée.
%   Y = MATLIBRE_RESEAU_ACTIVATION(RESEAU,X,COUCHE) applique le réseau
%   jusqu'à la couche demandée et rend ce qu'elle produit.
%
%   Exemple :
%      y = activations(net, X, 'relu_1');
%
%   Voir aussi DLNETWORK, ACTIVATIONS.
    couche = char(couche);
    if ~any(strcmp(reseau.Names, couche))
        error('nnet:activations:Couche', 'Aucune couche nommée « %s ».', couche);
    end
    tronque = reseau;
    tronque.OutputNames = {couche};
    sorties = matlibre_reseau_avant(tronque, {X}, false);
    y = sorties{1};
end
