function varargout = matlibre_id_comparer(modele, donnees, arguments)
%MATLIBRE_ID_COMPARER Confronte un modèle aux mesures.
%   [Y,AJUSTEMENT] = MATLIBRE_ID_COMPARER(MODELE,DONNEES,ARGUMENTS) rend
%   la sortie prédite et l'ajustement en pour cent.
%
%   L'ajustement vaut cent fois un moins le rapport de la norme de
%   l'erreur à celle de l'écart des mesures à leur moyenne : cent pour
%   cent est une reproduction exacte, zéro vaut la moyenne constante, et
%   un nombre négatif est pire que de ne rien prédire du tout.
%
%   Sans horizon donné, la comparaison est faite en simulation — le
%   modèle n'utilise alors que l'entrée, jamais la sortie mesurée.
%
%   Exemple :
%      [y, ajustement] = compare(m, z);
%
%   Voir aussi PREDICT, RESID, GOODNESSOFFIT.
    horizon = Inf;
    for k = 1:numel(arguments)
        if isnumeric(arguments{k}) && isscalar(arguments{k})
            horizon = arguments{k};
        end
    end
    jeu = matlibre_id_experience(iddata(donnees), 1);
    prediction = matlibre_id_predire(modele, jeu, horizon);
    ajustement = compareFit(jeu.OutputData, prediction.OutputData);
    if nargout == 0
        matlibre_id_tracer_comparaison(jeu, prediction, ajustement);
        varargout = {};
        return
    end
    varargout = {prediction, ajustement};
    varargout = varargout(1:min(max(nargout, 1), 2));
end
