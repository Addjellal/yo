function obj = matlibre_garch_verifier(obj)
%MATLIBRE_GARCH_VERIFIER Refuse un modèle dont un coefficient manque.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isnan(obj.Constant)
        error('econ:garch:Incomplet', ...
              'The constant is not set: estimate the model first.');
    end
    if isnan(obj.Offset)
        obj.Offset = 0;
    end
    listes = {'GARCH', 'ARCH'};
    for k = 1:numel(listes)
        coefficients = obj.(listes{k});
        for j = 1:numel(coefficients)
            if isnan(coefficients{j})
                error('econ:garch:Incomplet', ...
                      ['Coefficient %s number %d is not set: ' ...
                       'estimate the model first.'], listes{k}, j);
            end
        end
    end
end
