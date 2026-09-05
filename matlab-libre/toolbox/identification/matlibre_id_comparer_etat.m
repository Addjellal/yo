function varargout = matlibre_id_comparer_etat(modele, donnees, arguments)
%MATLIBRE_ID_COMPARER_ETAT Confronte un modèle d'état aux mesures.
%   [Y,AJUSTEMENT] = MATLIBRE_ID_COMPARER_ETAT(MODELE,DONNEES,ARGUMENTS)
%   rend la sortie prédite et l'ajustement en pour cent.
%
%   Exemple :
%      [y, ajustement] = compare(n4sid(z, 2), z);
%
%   Voir aussi COMPARE, IDSS.
    horizon = Inf;
    for k = 1:numel(arguments)
        if isnumeric(arguments{k}) && isscalar(arguments{k})
            horizon = arguments{k};
        end
    end
    jeu = matlibre_id_experience(iddata(donnees), 1);
    prediction = matlibre_id_predire_etat(modele, jeu, horizon);
    ajustement = compareFit(jeu.OutputData, prediction.OutputData);
    if nargout == 0
        matlibre_id_tracer_comparaison(jeu, prediction, ajustement);
        varargout = {};
        return
    end
    varargout = {prediction, ajustement};
    varargout = varargout(1:min(max(nargout, 1), 2));
end
