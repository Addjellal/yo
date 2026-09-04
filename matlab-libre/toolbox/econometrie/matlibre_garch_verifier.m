function obj = matlibre_garch_verifier(obj)
%MATLIBRE_GARCH_VERIFIER Refuse un modèle dont un coefficient manque.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isnan(obj.Constant)
        error('econ:garch:Incomplet', ...
              'La constante n''est pas fixée : estimez le modèle d''abord.');
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
                      ['Le coefficient %s numéro %d n''est pas fixé : ' ...
                       'estimez le modèle d''abord.'], listes{k}, j);
            end
        end
    end
end
