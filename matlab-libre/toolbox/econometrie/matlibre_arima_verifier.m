function obj = matlibre_arima_verifier(obj)
%MATLIBRE_ARIMA_VERIFIER Refuse un modèle dont un coefficient manque.
%   Simuler ou prévoir demande un modèle complet ; seul ESTIMATE accepte
%   des NaN, puisque c'est son travail de les remplacer.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isnan(obj.Constant)
        obj.Constant = 0;
    end
    if isnan(obj.Variance)
        obj.Variance = 1;
    end
    listes = {'AR', 'SAR', 'MA', 'SMA'};
    for k = 1:numel(listes)
        coefficients = obj.(listes{k});
        for j = 1:numel(coefficients)
            if isnan(coefficients{j})
                error('econ:arima:Incomplet', ...
                      ['Le coefficient %s numéro %d n''est pas fixé : ' ...
                       'estimez le modèle d''abord.'], listes{k}, j);
            end
        end
    end
end
