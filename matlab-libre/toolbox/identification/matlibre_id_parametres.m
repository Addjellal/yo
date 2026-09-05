function p = matlibre_id_parametres(modele)
%MATLIBRE_ID_PARAMETRES Paramètres libres d'un modèle polynomial.
%   P = MATLIBRE_ID_PARAMETRES(MODELE) rend, à la file, les coefficients
%   de A, B, C, D et F qui ne sont pas fixés : le terme constant de A, C,
%   D et F vaut un par construction, et les zéros de tête de B portent le
%   retard.
%
%   Exemple :
%      getpvec(idpoly([1 -0.8], [0 0.2]))      % -0.8  0.2
%
%   Voir aussi SETPVEC, POLYEST.
    nk = matlibre_id_retard_modele(modele);
    p = [modele.A(2:end), modele.B((nk + 1):end), ...
         modele.C(2:end), modele.D(2:end), modele.F(2:end)].';
end
