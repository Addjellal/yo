function [donnees, nullidx, pilotidx] = matlibre_ofdm_indices(nfft, nullidx, pilotidx, fonction)
%MATLIBRE_OFDM_INDICES Indices des sous-porteuses de données d'une grille OFDM.
%   [DONNEES,NULLIDX,PILOTIDX] = MATLIBRE_OFDM_INDICES(NFFT,NULLIDX,
%   PILOTIDX,FONCTION) vérifie les indices nuls et pilotes (entre 1 et
%   NFFT, distincts) et rend, en colonne et dans l'ordre croissant, les
%   indices qui restent aux données.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      d = matlibre_ofdm_indices(64, [1:6 33 60:64].', [12 26 40 54].', 'ofdmmod');
%      numel(d)                    % 48 : les données de 802.11a
%
%   Voir aussi OFDMMOD, OFDMDEMOD.
    if ~isscalar(nfft) || nfft < 8 || nfft ~= fix(nfft)
        error(['comm:' fonction ':NFFT'], 'NFFT must be an integer greater than or equal to 8.');
    end
    nullidx = nullidx(:);
    pilotidx = pilotidx(:);
    tous = [nullidx; pilotidx];
    if any(tous < 1) || any(tous > nfft) || any(tous ~= fix(tous)) ...
            || numel(unique(tous)) ~= numel(tous)
        error(['comm:' fonction ':Indices'], ...
              'Null and pilot indices must be distinct integers between 1 and NFFT.');
    end
    donnees = setdiff((1:nfft).', tous);
end
