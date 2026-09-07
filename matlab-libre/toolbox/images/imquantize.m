function [indices, valeurs] = imquantize(image, seuils, niveaux)
%IMQUANTIZE Quantifie une image selon des seuils.
%   IDX = IMQUANTIZE(I,SEUILS) rend l'indice de classe, de 1 à
%   numel(SEUILS)+1. [IDX,V] = IMQUANTIZE(...,NIVEAUX) rend aussi l'image
%   reconstruite avec les valeurs données.
%
%   Exemple :
%      indices = imquantize([0.1 0.4 0.9], [0.3 0.6]);
%      indices                     % 1 2 3 : trois classes pour deux seuils
    x = double(image);
    indices = ones(size(x));
    for k = 1:numel(seuils)
        indices(x > seuils(k)) = k + 1;
    end
    if nargout > 1
        if nargin < 3 || isempty(niveaux)
            niveaux = (0:numel(seuils)) / max(numel(seuils), 1);
        end
        valeurs = niveaux(indices);
        valeurs = reshape(valeurs, size(x));
    end
end
