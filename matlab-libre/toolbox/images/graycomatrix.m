function [glcm, niveauxUtilises] = graycomatrix(image, varargin)
%GRAYCOMATRIX Matrice de cooccurrence des niveaux de gris.
%   GLCM = GRAYCOMATRIX(I) compte les couples de pixels voisins à droite,
%   après quantification sur 8 niveaux. Options : 'NumLevels',
%   'GrayLimits', 'Offset' (matrice de décalages [dl dc], une ligne par
%   décalage).
%
%   Exemple :
%      graycomatrix([1 1 1; 1 1 1; 1 1 1], 'NumLevels', 2)
    niveaux = 8;
    limites = [];
    decalages = [0 1];
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'numlevels',  niveaux = varargin{k + 1};
            case 'graylimits', limites = varargin{k + 1};
            case 'offset',     decalages = varargin{k + 1};
        end
    end
    x = double(image);
    if isempty(limites)
        limites = [min(x(:)), max(x(:))];
    end
    if limites(2) <= limites(1)
        quantifie = ones(size(x));
    else
        quantifie = floor((x - limites(1)) / (limites(2) - limites(1)) * (niveaux - 1e-9)) + 1;
        quantifie = min(max(quantifie, 1), niveaux);
    end
    [m, n] = size(quantifie);
    nombreDecalages = size(decalages, 1);
    glcm = zeros(niveaux, niveaux, nombreDecalages);
    for d = 1:nombreDecalages
        dl = decalages(d, 1);
        dc = decalages(d, 2);
        for i = 1:m
            for j = 1:n
                i2 = i + dl;
                j2 = j + dc;
                if i2 < 1 || i2 > m || j2 < 1 || j2 > n, continue, end
                glcm(quantifie(i, j), quantifie(i2, j2), d) = ...
                    glcm(quantifie(i, j), quantifie(i2, j2), d) + 1;
            end
        end
    end
    if nombreDecalages == 1
        glcm = glcm(:, :, 1);
    end
    niveauxUtilises = quantifie;
end
