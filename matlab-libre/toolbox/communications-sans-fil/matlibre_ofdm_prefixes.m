function cp = matlibre_ofdm_prefixes(cplen, nSym, nfft, fonction)
%MATLIBRE_OFDM_PREFIXES Longueurs de préfixe cyclique, une par symbole.
%   CP = MATLIBRE_OFDM_PREFIXES(CPLEN,NSYM,NFFT,FONCTION) développe un
%   scalaire en NSYM longueurs, ou vérifie une ligne de NSYM longueurs.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      cp = matlibre_ofdm_prefixes(16, 3, 64, 'ofdmmod')     % 16 16 16
%
%   Voir aussi OFDMMOD, OFDMDEMOD.
    if isscalar(cplen)
        cp = repmat(cplen, 1, nSym);
        if cplen > nfft
            error(['comm:' fonction ':Prefixe'], 'Un préfixe scalaire ne dépasse pas NFFT.');
        end
    elseif isvector(cplen) && numel(cplen) == nSym
        cp = cplen(:).';
    else
        error(['comm:' fonction ':Prefixe'], ...
              'CPLEN est un scalaire ou une ligne d''une longueur par symbole (%d).', nSym);
    end
    if any(cp < 0) || any(cp ~= fix(cp))
        error(['comm:' fonction ':Prefixe'], 'Les préfixes sont des entiers positifs ou nuls.');
    end
end
