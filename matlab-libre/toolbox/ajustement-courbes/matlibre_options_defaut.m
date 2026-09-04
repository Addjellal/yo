function options = matlibre_options_defaut()
%MATLIBRE_OPTIONS_DEFAUT Réglages d'ajustement par défaut.
%   OPT = MATLIBRE_OPTIONS_DEFAUT() rend la structure complète, tous
%   champs présents : c'est ce qui permet à FIT de les lire sans avoir à
%   vérifier chaque fois qu'ils existent.
%
%   Exemple :
%      matlibre_options_defaut().MaxIter      % 400
%
%   Voir aussi FITOPTIONS, FIT.
    options = struct('Method', 'LinearLeastSquares', 'Robust', 'off', ...
                     'StartPoint', [], 'Lower', [], 'Upper', [], ...
                     'Weights', [], 'Exclude', [], 'Normalize', 'off', ...
                     'MaxIter', 400, 'MaxFunEvals', 2000, ...
                     'TolFun', 1e-8, 'TolX', 1e-8, ...
                     'SmoothingParam', [], 'Span', 0.25, 'Display', 'notify');
end
