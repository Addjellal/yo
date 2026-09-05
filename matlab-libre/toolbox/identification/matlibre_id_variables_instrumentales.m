function theta = matlibre_id_variables_instrumentales(y, u, instrument, ordres)
%MATLIBRE_ID_VARIABLES_INSTRUMENTALES Une passe de variables instrumentales.
%   THETA = MATLIBRE_ID_VARIABLES_INSTRUMENTALES(Y,U,INSTRUMENT,ORDRES)
%   résout Z'Phi theta = Z'Y, où Phi porte les régresseurs et Z les
%   instruments — les mêmes régresseurs, mais construits sur une sortie
%   simulée, donc sans bruit.
%
%   Exemple :
%      theta = matlibre_id_variables_instrumentales(y, u, x, [1 1 0 0 0 1]);
%
%   Voir aussi IV4, ARX.
    [Phi, cible] = matlibre_id_regression(y, u, ordres);
    [Z, ~] = matlibre_id_regression(instrument, u, ordres);
    theta = (Z.' * Phi) \ (Z.' * cible);
end
