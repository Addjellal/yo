function y = matlibre_dl_concatener(dimension, operandes)
%MATLIBRE_DL_CONCATENER Mise bout à bout de DLARRAY, avec sa dérivée.
%   Y = MATLIBRE_DL_CONCATENER(DIMENSION,OPERANDES) concatène le contenu
%   des opérandes le long de DIMENSION. À la dérivation, le gradient est
%   redécoupé et rendu à chacun.
%
%   Exemple :
%      y = matlibre_dl_concatener(2, {dlarray(1), dlarray(2)});
%      extractdata(y)     % 1 2
%
%   Voir aussi DLARRAY, CAT.
    valeurs = cell(1, numel(operandes));
    tailles = cell(1, numel(operandes));
    parents = zeros(1, numel(operandes));
    format = '';
    for k = 1:numel(operandes)
        valeurs{k} = matlibre_dl_valeur(operandes{k});
        tailles{k} = size(valeurs{k});
        parents(k) = matlibre_dl_noeud(operandes{k});
        if isempty(format)
            format = matlibre_dl_format(operandes{k});
        end
    end
    valeur = cat(dimension, valeurs{:});
    noeud = matlibre_bande('ajouter', 'concatenation', parents, {dimension, tailles});
    y = matlibre_dl_construire(valeur, format, noeud);
end
