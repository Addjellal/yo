function valeur = normalized2actual(atome, normalise)
%NORMALIZED2ACTUAL Passe de la valeur normalisée d'un paramètre à sa valeur réelle.
%   V = NORMALIZED2ACTUAL(P,N) fait l'inverse d'ACTUAL2NORMALIZED : elle
%   rend la valeur réelle du paramètre P qui correspond à la valeur
%   normalisée N. Zéro donne le nominal, un la borne haute, moins un la
%   borne basse.
%
%   N peut être un tableau ; V a la même taille.
%
%   Exemples :
%      p = ureal('p', 10, 'Range', [8 15]);
%      normalized2actual(p, 0)            % 10
%      normalized2actual(p, 1)            % 15
%      normalized2actual(p, -1)           % 8
%      normalized2actual(p, actual2normalized(p, 12))    % 12
%
%   Voir aussi ACTUAL2NORMALIZED, UREAL, ROBSTAB, WCGAIN.
    [nominal, bas, haut] = matlibre_bornes_atome(atome);
    normalise = double(normalise);
    valeur = zeros(size(normalise));
    for k = 1:numel(normalise)
        if normalise(k) >= 0
            valeur(k) = nominal + normalise(k) * (haut - nominal);
        else
            valeur(k) = nominal + normalise(k) * (nominal - bas);
        end
    end
end
