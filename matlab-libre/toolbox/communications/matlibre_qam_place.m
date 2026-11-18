function [colonne, ligne] = matlibre_qam_place(s, cote, ordre)
%MATLIBRE_QAM_PLACE Colonne et ligne d'un symbole sur la grille QAM de MATLAB.
%   [C,L] = MATLIBRE_QAM_PLACE(S,COTE,ORDRE) : colonnes comptées de la
%   gauche, lignes du haut, à partir de zéro.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [c, l] = matlibre_qam_place(13, 4, 'gray')    % colonne 2, ligne 1
%
%   Voir aussi QAMMOD, MATLIBRE_QAM_SYMBOLE.
    if ischar(ordre) || isstring(ordre)
        colonne = matlibre_comm_position(floor(s / cote), cote, ordre);
        ligne = matlibre_comm_position(mod(s, cote), cote, ordre);
    else
        place = zeros(1, cote ^ 2);
        place(ordre(:).' + 1) = 0:cote ^ 2 - 1;
        p = reshape(place(s(:) + 1), size(s));
        colonne = floor(p / cote);
        ligne = mod(p, cote);
    end
end
