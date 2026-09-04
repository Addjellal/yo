function perte = matlibre_dl_reduire_perte(termes, reduction, facteur, format)
%MATLIBRE_DL_REDUIRE_PERTE Cumule et normalise les termes d'une perte.
%   P = MATLIBRE_DL_REDUIRE_PERTE(TERMES,REDUCTION,FACTEUR,FORMAT) somme
%   les termes puis divise selon le facteur demandé, ou les rend tels
%   quels si REDUCTION vaut 'none'.
%
%   Exemple :
%      matlibre_dl_reduire_perte([1 3], 'sum', 'batch-size', 'CB')     % 2
%
%   Voir aussi L1LOSS, L2LOSS, HUBER.
    if strcmpi(reduction, 'none')
        perte = termes;
        return
    end
    perte = sum(termes(:));
    perte = perte / matlibre_dl_effectif(termes, facteur, format);
end
