function mode = matlibre_mode_ondelette(mode)
%MATLIBRE_MODE_ONDELETTE Valide un mode de prolongement des bords.
%   Les modes de MATLAB : 'zpd', 'sym' ou 'symh', 'symw', 'asym' ou
%   'asymh', 'asymw', 'sp0', 'spd' ou 'sp1', 'ppd', 'per'.
    if ~(ischar(mode) || (isstring(mode) && isscalar(mode)))
        error('Wavelet:FunctionArgVal:Invalid_ExtMode', ...
              'Le mode de prolongement est un texte, comme ''sym'' ou ''per''.');
    end
    mode = lower(char(mode));
    connus = {'zpd', 'sym', 'symh', 'symw', 'asym', 'asymh', 'asymw', ...
              'sp0', 'spd', 'sp1', 'ppd', 'per'};
    if ~any(strcmp(mode, connus))
        error('Wavelet:FunctionArgVal:Invalid_ExtMode', ...
              'Mode de prolongement inconnu : ''%s''. Modes : %s.', mode, strjoin(connus, ', '));
    end
end
