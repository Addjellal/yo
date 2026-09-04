function c = featureInputLayer(n, varargin)
%FEATUREINPUTLAYER Couche d'entrée pour des vecteurs de caractéristiques.
    c = struct('type', 'input', 'taille', n, 'nom', matlibre_couche_nom(varargin));
end
