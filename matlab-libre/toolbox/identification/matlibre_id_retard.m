function nk = matlibre_id_retard(B)
%MATLIBRE_ID_RETARD Retard lu dans les zéros de tête du numérateur.
%   NK = MATLIBRE_ID_RETARD(B) compte les zéros qui précèdent le premier
%   coefficient non nul. Un modèle dont l'entrée n'agit qu'au bout de deux
%   périodes a donc un B commençant par deux zéros.
%
%   Exemple :
%      matlibre_id_retard([0 0 0.2])      % 2
%
%   Voir aussi IDPOLY, POLYEST.
    nk = 0;
    for k = 1:numel(B)
        if B(k) ~= 0
            break
        end
        nk = nk + 1;
    end
    if nk == numel(B)
        nk = 0;
    end
end
