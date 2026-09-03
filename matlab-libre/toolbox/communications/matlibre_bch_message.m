function [valeurs, estCorps] = matlibre_bch_message(message, k)
%MATLIBRE_BCH_MESSAGE Ramène un message à une matrice de lignes de K bits.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    estCorps = isa(message, 'gf');
    valeurs = matlibre_gf_valeurs(message);
    if isvector(valeurs)
        valeurs = valeurs(:).';
    end
    if size(valeurs, 2) ~= k
        if mod(numel(valeurs), k) == 0
            valeurs = reshape(valeurs(:).', k, []).';
        else
            error('comm:bch:Longueur', ...
                  'Le message doit compter %d colonnes.', k);
        end
    end
    if any(valeurs(:) ~= 0 & valeurs(:) ~= 1)
        error('comm:bch:Binaire', 'Le message doit être binaire.');
    end
end
