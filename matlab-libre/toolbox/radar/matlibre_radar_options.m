function o = matlibre_radar_options(arguments, fonction, permis)
%MATLIBRE_RADAR_OPTIONS Les options nom-valeur de l'équation du radar.
%   O = MATLIBRE_RADAR_OPTIONS(ARGS,NOM,PERMIS) lit RCS (m^2, 1), Ts (K,
%   290), Gain (dB, 20 ; scalaire, ou [Gt Gr]), Loss (dB, 0),
%   CustomFactor (dB, 0), AtmosphericLoss et PropagationFactor (dB, 0) et
%   unitstr ('m', 'km', 'mi', 'nmi') parmi les noms PERMIS.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      o = matlibre_radar_options({'Gain', 30}, 'radareqpow', {'Gain'});
%      o.Gain                     % [30 30]
%
%   Voir aussi RADAREQPOW, RADAREQRNG, RADAREQSNR.
    o = struct('RCS', 1, 'Ts', 290, 'Gain', [20 20], 'Loss', 0, 'CustomFactor', 0, ...
               'AtmosphericLoss', 0, 'PropagationFactor', 0, 'unitstr', 'm');
    if mod(numel(arguments), 2) ~= 0
        error(['phased:' fonction ':Options'], 'Options must come in name-value pairs.');
    end
    for k = 1:2:numel(arguments)
        nom = char(arguments{k});
        rang = find(strcmpi(nom, permis), 1);
        if isempty(rang)
            error(['phased:' fonction ':Options'], 'Unknown option for %s: %s.', ...
                  upper(fonction), nom);
        end
        valeur = arguments{k + 1};
        switch lower(permis{rang})
            case 'gain'
                valeur = double(valeur(:)');
                if isscalar(valeur)
                    valeur = [valeur valeur];
                end
                if numel(valeur) ~= 2
                    error(['phased:' fonction ':Gain'], ...
                          'Gain must be a scalar or [Gt Gr], in dB.');
                end
            case 'unitstr'
                valeur = lower(char(valeur));
                if ~any(strcmp(valeur, {'m', 'km', 'mi', 'nmi'}))
                    error(['phased:' fonction ':Unite'], ...
                          'unitstr must be ''m'', ''km'', ''mi'' or ''nmi''.');
                end
            otherwise
                valeur = double(valeur);
        end
        o.(permis{rang}) = valeur;
    end
    if any(o.RCS(:) <= 0) || any(o.Ts(:) <= 0)
        error(['phased:' fonction ':Valeur'], 'RCS and Ts must be positive.');
    end
end
