function [b1, b2, a11, a22, a12] = matlibre_expansion_polynomiale(I, voisinage)
%MATLIBRE_EXPANSION_POLYNOMIALE Approche l'image par un polynôme local.
%   [B1,B2,A11,A22,A12] = MATLIBRE_EXPANSION_POLYNOMIALE(I,VOISINAGE)
%   ajuste, autour de chaque pixel et au sens des moindres carrés
%   pondérés, la surface
%
%      f(x,y) = c + b1 x + b2 y + a11 x² + a22 y² + 2 a12 xy
%
%   et rend les coefficients, un plan chacun. C'est l'expansion sur
%   laquelle repose le flot optique de Farnebäck : deux images qui ne
%   diffèrent que d'un déplacement ont des polynômes liés par une
%   relation simple, d'où l'on tire ce déplacement.
%
%   La pondération est gaussienne, d'écart type le quart du voisinage
%   augmenté de deux, ce qui donne au bord de la fenêtre un poids faible
%   mais non nul.
%
%   Exemple :
%      [~, ~, a11] = matlibre_expansion_polynomiale((1:9).^2, 5);
%      a11(5)   % 1, le coefficient de x²
%
%   Voir aussi OPTICALFLOWFARNEBACK.
    I = double(I);
    rayon = max(1, floor(voisinage / 2));
    [dx, dy] = meshgrid(-rayon:rayon, -rayon:rayon);
    sigma = (2 * rayon + 3) / 4;
    poids = exp(-(dx .^ 2 + dy .^ 2) / (2 * sigma ^ 2));
    poids = poids / sum(poids(:));
    base = {ones(size(dx)), dx, dy, dx .^ 2, dy .^ 2, dx .* dy};
    % La matrice normale ne dépend pas du pixel : la fenêtre et ses poids
    % sont les mêmes partout. Elle s'inverse donc une fois pour toutes.
    G = zeros(6);
    for i = 1:6
        for j = 1:6
            G(i, j) = sum(sum(poids .* base{i} .* base{j}));
        end
    end
    correlations = cell(1, 6);
    for i = 1:6
        correlations{i} = imfilter(I, poids .* base{i}, 'replicate');
    end
    inverse = inv(G);
    coefficients = cell(1, 6);
    for i = 1:6
        somme = zeros(size(I));
        for j = 1:6
            if inverse(i, j) ~= 0
                somme = somme + inverse(i, j) * correlations{j};
            end
        end
        coefficients{i} = somme;
    end
    b1 = coefficients{2};
    b2 = coefficients{3};
    a11 = coefficients{4};
    a22 = coefficients{5};
    % Le terme croisé du polynôme est 2*a12 ; le coefficient ajusté vaut
    % donc la moitié de ce que rend l'ajustement.
    a12 = coefficients{6} / 2;
end
