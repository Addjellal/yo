function n = matlibre_dl_effectif(y, facteur, format)
%MATLIBRE_DL_EFFECTIF Par quoi diviser une perte cumulée.
%   N = MATLIBRE_DL_EFFECTIF(Y,FACTEUR,FORMAT) rend le nombre
%   d'observations pour 'batch-size', le nombre d'éléments pour
%   'all-elements', et un pour 'none'.
%
%   Exemple :
%      matlibre_dl_effectif(zeros(3, 8), 'batch-size', 'CB')     % 8
%
%   Voir aussi L1LOSS, L2LOSS, HUBER, CROSSENTROPY.
    switch lower(facteur)
        case 'batch-size'
            taille = size(y);
            [~, lot] = matlibre_dl_axe_canal(y, format);
            if lot > numel(taille)
                n = 1;
            else
                n = taille(lot);
            end
        case 'all-elements'
            n = numel(y);
        case 'none'
            n = 1;
        otherwise
            error('nnet:perte:Normalisation', ...
                  'Facteur de normalisation inconnu : %s.', facteur);
    end
end
