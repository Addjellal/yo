function correspondance = tableGray(modulation, M)
%TABLEGRAY Table de renumérotation de Gray d'une constellation.
%   CORRESPONDANCE(k+1) est le numéro de Gray du symbole binaire k. Pour
%   les constellations à une dimension c'est le code de Gray usuel ; pour
%   'qam' carrée, le code s'applique à chacune des deux coordonnées.
    modulation = lower(char(modulation));
    M = double(M);
    if M < 2 || abs(log2(M) - round(log2(M))) > 0
        error('comm:tableGray:BadOrder', 'M doit être une puissance de deux.');
    end
    unidimensionnel = @(v) bitxor(v, floor(v / 2));
    switch modulation
        case {'psk', 'dpsk', 'pam', 'fsk'}
            correspondance = unidimensionnel(0:M-1);
        case 'qam'
            cote = sqrt(M);
            if abs(cote - round(cote)) > 0
                % Constellation non carrée : on retombe sur le code de
                % Gray à une dimension, faute de deux axes séparables.
                correspondance = unidimensionnel(0:M-1);
                return
            end
            cote = round(cote);
            correspondance = zeros(1, M);
            for k = 0:M-1
                ligne = floor(k / cote);
                colonne = mod(k, cote);
                correspondance(k + 1) = unidimensionnel(ligne) * cote + unidimensionnel(colonne);
            end
        otherwise
            error('comm:tableGray:BadModulation', ...
                  'Modulation inconnue : %s.', modulation);
    end
end
