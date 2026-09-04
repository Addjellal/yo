function resume = summarize(modele)
%SUMMARIZE Résumé d'un modèle, ajusté ou non.
%   SUMMARIZE(MDL) écrit le modèle. Si MDL vient d'ESTIMATE, le résumé
%   donne les estimations, leurs écarts types, les rapports de Student,
%   les valeurs p, la log-vraisemblance et les critères d'information.
%
%   S = SUMMARIZE(MDL) rend la structure au lieu de l'écrire.
%
%   Exemple :
%      ajuste = estimate(arima(1, 0, 0), y, 'Display', 'off');
%      summarize(ajuste)
%
%   Voir aussi ARIMA, GARCH, ESTIMATE, AICBIC.
    if ~isa(modele, 'arima') && ~isa(modele, 'garch')
        error('econ:summarize:Modele', ...
              'SUMMARIZE attend un modèle ARIMA ou GARCH.');
    end
    if ~modele.Estimated
        if nargout > 0
            resume = struct('Estimated', false, 'Model', modele);
        else
            disp(modele);
        end
        return
    end
    noms = modele.EstimatedNames;
    valeurs = modele.EstimatedValues;
    if isempty(noms)
        [noms, valeurs] = matlibre_modele_parametres(modele);
    end
    covariance = modele.ParamCovariance;
    if isempty(covariance) || any(size(covariance) ~= numel(valeurs))
        ecarts = nan(numel(valeurs), 1);
    else
        diagonale = diag(covariance);
        diagonale(diagonale < 0) = NaN;
        ecarts = sqrt(diagonale);
    end
    observations = numel(modele.EstimatedResiduals);
    [aic, bic] = aicbic(modele.LogL, numel(valeurs), observations);
    if nargout > 0
        resume = struct('Estimated', true, 'Description', matlibre_arima_titre(modele), ...
                        'ParameterNames', {noms}, 'ParameterValues', valeurs(:), ...
                        'StandardErrors', ecarts(:), 'LogLikelihood', modele.LogL, ...
                        'AIC', aic, 'BIC', bic, 'SampleSize', observations, ...
                        'Covariance', covariance);
        return
    end
    information = struct('parametres', {noms}, 'valeurs', valeurs(:), ...
                         'logL', modele.LogL, 'observations', observations, ...
                         'residus', modele.EstimatedResiduals);
    matlibre_arima_resumer(modele, information, covariance);
end
