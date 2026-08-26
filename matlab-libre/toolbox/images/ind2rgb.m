function rgb = ind2rgb(indices, carte)
%IND2RGB Image indexée vers image en couleurs.
    indices = double(indices);
    carte = double(carte);
    if min(indices(:)) >= 0 && max(indices(:)) <= size(carte, 1) - 1
        indices = indices + 1;
    end
    indices = max(1, min(size(carte, 1), round(indices)));
    d = size(indices);
    rgb = zeros([d 3]);
    for plan = 1:3
        valeurs = carte(:, plan);
        rgb(:, :, plan) = reshape(valeurs(indices), d);
    end
end
