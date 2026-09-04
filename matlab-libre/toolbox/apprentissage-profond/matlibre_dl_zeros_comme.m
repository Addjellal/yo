function z = matlibre_dl_zeros_comme(conteneur)
%MATLIBRE_DL_ZEROS_COMME Conteneur de mêmes formes, rempli de zéros.
%   Z = MATLIBRE_DL_ZEROS_COMME(C) sert à démarrer l'état d'un solveur :
%   les moyennes glissantes partent de zéro, avec exactement la forme des
%   paramètres qu'elles suivront.
%
%   Exemple :
%      z = matlibre_dl_zeros_comme({[1 2], 3});
%      z{1}      % 0 0
%
%   Voir aussi ADAMUPDATE, SGDMUPDATE, RMSPROPUPDATE.
    z = matlibre_dl_combiner(@(x) zeros(size(matlibre_dl_valeur(x))), conteneur);
end
