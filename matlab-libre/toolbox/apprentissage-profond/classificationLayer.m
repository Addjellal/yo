function c = classificationLayer()
%CLASSIFICATIONLAYER Couche de sortie pour la classification.
%   Elle déclare que le coût est l'entropie croisée ; elle n'a pas de
%   paramètre et ne transforme pas la sortie.
    c = struct('type', 'classification');
end
