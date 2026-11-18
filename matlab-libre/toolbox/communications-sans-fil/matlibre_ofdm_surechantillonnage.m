function matlibre_ofdm_surechantillonnage(arguments, fonction)
%MATLIBRE_OFDM_SURECHANTILLONNAGE Refuse un facteur de suréchantillonnage autre que un.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_ofdm_surechantillonnage({'OversamplingFactor', 1}, 'ofdmmod')
%
%   Voir aussi OFDMMOD, OFDMDEMOD.
    for k = 1:2:numel(arguments)
        if ~strcmpi(arguments{k}, 'OversamplingFactor') || k == numel(arguments)
            error(['comm:' fonction ':Option'], ...
                  'La seule option est ''OversamplingFactor''.');
        end
        if arguments{k + 1} ~= 1
            error(['comm:' fonction ':Surechantillonnage'], ...
                  'MatLibre ne suréchantillonne pas encore les symboles OFDM : le facteur vaut un.');
        end
    end
end
