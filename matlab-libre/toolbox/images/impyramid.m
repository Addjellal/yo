function sortie = impyramid(image, direction)
%IMPYRAMID Un étage de pyramide gaussienne, vers le haut ou vers le bas.
%   IMPYRAMID(A,'reduce') divise la taille par deux après lissage ;
%   'expand' la double.
%
%   Le noyau est le noyau binomial 5 x 5 de Burt et Adelson, celui que
%   MATLAB emploie : [1 4 6 4 1]/16 dans chaque direction.
    noyau = [1 4 6 4 1] / 16;
    image = double(image);
    if strncmpi(char(direction), 'red', 3)
        separable = noyau' * noyau;
        lisse = conv2(padarray(image, [2 2], 'replicate', 'both'), separable, 'valid');
        sortie = lisse(1:2:end, 1:2:end);
    else
        [h, l] = size(image);
        agrandi = zeros(2 * h - 1, 2 * l - 1);
        agrandi(1:2:end, 1:2:end) = image;
        separable = noyau' * noyau;
        sortie = 4 * conv2(padarray(agrandi, [2 2], 'replicate', 'both'), separable, 'valid');
    end
end
