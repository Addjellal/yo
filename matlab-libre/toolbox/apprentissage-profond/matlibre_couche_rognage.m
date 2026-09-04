function bords = matlibre_couche_rognage(specification, grande, entree, pas)
%MATLIBRE_COUCHE_ROGNAGE Ce qu'on retire des bords d'une convolution transposée.
%   B = MATLIBRE_COUCHE_ROGNAGE(SPEC,GRANDE,ENTREE,PAS) rend
%   [haut bas gauche droite]. SPEC vaut un nombre, un couple, ou 'same' —
%   qui rogne de façon que la sortie fasse exactement l'entrée multipliée
%   par le pas.
%
%   Exemple :
%      matlibre_couche_rognage('same', [10 10], [5 5], [2 2])
%
%   Voir aussi TRANSPOSEDCONV2DLAYER.
    if ischar(specification)
        if ~strcmpi(specification, 'same')
            error('nnet:transposedconv:Rognage', ...
                  'Rognage inconnu : %s.', specification);
        end
        vise = entree .* pas;
        bords = zeros(1, 4);
        for d = 1:2
            total = max(grande(d) - vise(d), 0);
            avant = floor(total / 2);
            bords(2 * d - 1) = avant;
            bords(2 * d) = total - avant;
        end
        return
    end
    specification = double(specification);
    if isscalar(specification)
        bords = specification * ones(1, 4);
    elseif numel(specification) == 2
        bords = [specification(1) specification(1) specification(2) specification(2)];
    else
        specification = reshape(specification, 2, 2);
        bords = [specification(1, 1) specification(2, 1) ...
                 specification(1, 2) specification(2, 2)];
    end
end
