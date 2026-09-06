function c = featureInputLayer(n, varargin)
%FEATUREINPUTLAYER Couche d'entrée pour des vecteurs de caractéristiques.
%   C = FEATUREINPUTLAYER(N) déclare une entrée de N caractéristiques
%   numériques, une observation par colonne. C'est l'entrée d'un réseau
%   qui travaille sur des mesures déjà extraites — âge, tension, débit —
%   et non sur une image dont la disposition spatiale importe.
%
%   C = FEATUREINPUTLAYER(N,'Name',NOM) nomme la couche.
%
%   Le choix de la couche d'entrée n'est pas cosmétique : IMAGEINPUTLAYER
%   annonce aux couches suivantes une grille à deux dimensions, sur
%   laquelle une convolution a un sens ; FEATUREINPUTLAYER annonce un
%   vecteur, dont l'ordre des composantes est arbitraire.
%
%   Exemple :
%      couches = [featureInputLayer(4); fullyConnectedLayer(3); softmaxLayer()];
%
%   Voir aussi IMAGEINPUTLAYER, SEQUENCEINPUTLAYER, FULLYCONNECTEDLAYER.
    c = struct('type', 'input', 'taille', n, 'nom', matlibre_couche_nom(varargin));
end
