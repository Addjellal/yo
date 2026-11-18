function s = matlibre_qam_symbole(colonne, ligne, cote, ordre)
%MATLIBRE_QAM_SYMBOLE Symbole porté par un point de la grille QAM de MATLAB.
%   S = MATLIBRE_QAM_SYMBOLE(C,L,COTE,ORDRE), l'inverse de
%   MATLIBRE_QAM_PLACE.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_qam_symbole(2, 1, 4, 'gray')         % 13
%
%   Voir aussi QAMDEMOD, MATLIBRE_QAM_PLACE.
    if ischar(ordre) || isstring(ordre)
        s = matlibre_comm_symbole(colonne, cote, ordre) * cote ...
            + matlibre_comm_symbole(ligne, cote, ordre);
    else
        v = ordre(:).';
        s = reshape(v(colonne(:) * cote + ligne(:) + 1), size(colonne));
    end
end
