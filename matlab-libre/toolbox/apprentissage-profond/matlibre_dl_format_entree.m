function format = matlibre_dl_format_entree(x)
%MATLIBRE_DL_FORMAT_ENTREE Format d'un lot, d'après son nombre de dimensions.
%   F = MATLIBRE_DL_FORMAT_ENTREE(X) rend le format porté par X, ou celui
%   qu'impose la convention : 'CB' pour une matrice, 'SCB' pour un
%   tableau à trois dimensions, 'SSCB' pour un tableau à quatre.
%
%   Exemple :
%      matlibre_dl_format_entree(zeros(4, 8))      % CB
%
%   Voir aussi DLARRAY, BATCHNORM, LAYERNORM.
    if isa(x, 'dlarray') && ~isempty(dims(x))
        format = dims(x);
        return
    end
    switch ndims(x)
        case 2, format = 'CB';
        case 3, format = 'SCB';
        otherwise, format = 'SSCB';
    end
end
