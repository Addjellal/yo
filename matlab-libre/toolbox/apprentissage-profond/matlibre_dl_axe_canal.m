function [canal, lot, dimensions] = matlibre_dl_axe_canal(x, format)
%MATLIBRE_DL_AXE_CANAL Positions des dimensions de canal et d'observation.
%   [C,B,N] = MATLIBRE_DL_AXE_CANAL(X,FORMAT) rend la position de
%   l'étiquette 'C', celle de 'B', et le nombre de dimensions. Sans
%   format, la convention est celle de MATLAB : les observations en
%   dernier, les canaux juste avant.
%
%   Exemple :
%      [c, b] = matlibre_dl_axe_canal(zeros(4, 4, 3, 8), 'SSCB');   % 3, 4
%
%   Voir aussi BATCHNORM, LAYERNORM, GROUPNORM.
    if isempty(format) && isa(x, 'dlarray')
        format = dims(x);
    end
    dimensions = max(ndims(x), numel(format));
    if isempty(format)
        lot = dimensions;
        canal = max(1, dimensions - 1);
        return
    end
    format = upper(char(format));
    canal = find(format == 'C', 1);
    lot = find(format == 'B', 1);
    if isempty(canal)
        canal = max(1, dimensions - 1);
    end
    if isempty(lot)
        lot = dimensions;
    end
end
