function position = matlibre_dl_position_lot(format, dimensions)
%MATLIBRE_DL_POSITION_LOT Dimension qui porte les observations.
%   P = MATLIBRE_DL_POSITION_LOT(FORMAT,DIMENSIONS) rend la position de
%   l'étiquette 'B' dans le format, ou la dernière dimension quand aucun
%   format n'est donné — c'est là que se rangent les observations par
%   convention.
%
%   Exemple :
%      matlibre_dl_position_lot('SSCB', 4)     % 4
%      matlibre_dl_position_lot('', 3)         % 3
%
%   Voir aussi FULLYCONNECT, DLARRAY.
    position = [];
    if ~isempty(format)
        position = find(format == 'B', 1);
    end
    if isempty(position)
        position = dimensions;
    end
end
