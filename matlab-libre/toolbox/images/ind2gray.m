function image = ind2gray(indices, carte)
%IND2GRAY Image indexée vers niveaux de gris.
%   La luminance suit la même pondération que RGB2GRAY.
    indices = double(indices);
    carte = double(carte);
    if max(indices(:)) <= size(carte, 1) - 1 && min(indices(:)) >= 0
        indices = indices + 1;      % indices partant de zéro
    end
    indices = max(1, min(size(carte, 1), round(indices)));
    gris = carte * [0.298936021293775; 0.587043074451121; 0.114020904255103];
    image = reshape(gris(indices), size(indices));
end
