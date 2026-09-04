function [reduction, facteur, format] = matlibre_dl_options_perte(predit, arguments)
%MATLIBRE_DL_OPTIONS_PERTE Réglages communs aux fonctions de perte.
%   [R,F,FORMAT] = MATLIBRE_DL_OPTIONS_PERTE(Y,ARGUMENTS) lit
%   'Reduction', 'NormalizationFactor' et 'DataFormat'.
%
%   Exemple :
%      [r, f] = matlibre_dl_options_perte(1, {'Reduction', 'none'});
%
%   Voir aussi L1LOSS, L2LOSS, HUBER.
    reduction = 'sum';
    facteur = 'batch-size';
    format = '';
    if isa(predit, 'dlarray')
        format = dims(predit);
    end
    for k = 1:2:numel(arguments) - 1
        switch lower(char(arguments{k}))
            case 'reduction',           reduction = lower(char(arguments{k + 1}));
            case 'normalizationfactor', facteur = lower(char(arguments{k + 1}));
            case 'dataformat',          format = upper(char(arguments{k + 1}));
            case 'weights'
                % Non traité : la pondération par observation n'est pas
                % fournie.
            otherwise
                error('nnet:perte:Option', ...
                      'Option inconnue : %s.', char(arguments{k}));
        end
    end
end
