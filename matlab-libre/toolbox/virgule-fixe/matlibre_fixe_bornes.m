function [bas, haut] = matlibre_fixe_bornes(T)
%MATLIBRE_FIXE_BORNES Les entiers stockés extrêmes d'un type fixe.
%   [BAS,HAUT] = MATLIBRE_FIXE_BORNES(T) : de -2^(W-1) à 2^(W-1)-1 pour un
%   type signé de W bits, de 0 à 2^W-1 sinon.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi FI, UPPERBOUND, LOWERBOUND.
    w = T.WordLength;
    if T.Signed
        bas = -2 ^ (w - 1);
        haut = 2 ^ (w - 1) - 1;
    else
        bas = 0;
        haut = 2 ^ w - 1;
    end
end
