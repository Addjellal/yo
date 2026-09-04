function bords = matlibre_dl_remplissage(specification, taille, noyau, pas, dilatation)
%MATLIBRE_DL_REMPLISSAGE Épaisseur de zéros à ajouter autour de l'entrée.
%   B = MATLIBRE_DL_REMPLISSAGE(SPEC,TAILLE,NOYAU,PAS,DILATATION) rend
%   [haut bas gauche droite]. SPEC vaut un nombre, un couple, une matrice
%   deux par deux, ou 'same' — qui calcule l'épaisseur telle que la sortie
%   ait la taille de l'entrée divisée par le pas.
%
%   Exemple :
%      matlibre_dl_remplissage('same', [5 5], [3 3], [1 1], [1 1])   % 1 1 1 1
%
%   Voir aussi DLCONV.
    if ischar(specification)
        if ~strcmpi(specification, 'same')
            error('nnet:dlconv:Remplissage', ...
                  'Remplissage inconnu : %s.', specification);
        end
        bords = zeros(1, 4);
        for d = 1:2
            sortie = ceil(taille(d) / pas(d));
            total = max((sortie - 1) * pas(d) + (noyau(d) - 1) * dilatation(d) + 1 - taille(d), 0);
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
    elseif numel(specification) == 4
        % [haut gauche ; bas droite] dans la convention de MATLAB.
        specification = reshape(specification, 2, 2);
        bords = [specification(1, 1) specification(2, 1) ...
                 specification(1, 2) specification(2, 2)];
    else
        error('nnet:dlconv:Remplissage', ...
              'Le remplissage se donne par un nombre, un couple ou une matrice deux par deux.');
    end
end
