function mode = matlibre_couche_mode(arguments)
%MATLIBRE_COUCHE_MODE Mode de sortie d'une couche récurrente.
%   M = MATLIBRE_COUCHE_MODE(ARGUMENTS) lit l'option 'OutputMode' :
%   'sequence' rend toute la suite des sorties, 'last' seulement la
%   dernière.
%
%   Exemple :
%      matlibre_couche_mode({'OutputMode', 'last'})     % last
%
%   Voir aussi LSTMLAYER, GRULAYER, BILSTMLAYER.
    mode = 'sequence';
    for k = 1:2:numel(arguments) - 1
        if strcmpi(char(arguments{k}), 'outputmode')
            mode = lower(char(arguments{k + 1}));
        end
    end
end
