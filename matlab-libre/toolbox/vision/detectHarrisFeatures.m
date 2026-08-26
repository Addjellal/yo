function [positions, reponses] = detectHarrisFeatures(I, varargin)
%DETECTHARRISFEATURES Points d'intérêt par le détecteur de Harris.
%   [P,R] = DETECTHARRISFEATURES(I) rend les coordonnées [x y] des coins et
%   leur réponse. Option 'MinQuality' (0.01 par défaut).
    qualiteMin = 0.01;
    for k = 1:2:numel(varargin)-1
        if strcmpi(char(varargin{k}), 'minquality')
            qualiteMin = varargin{k+1};
        end
    end
    I = double(I);
    if ndims(I) == 3
        I = rgb2gray(I);
    end
    hx = [1 0 -1; 2 0 -2; 1 0 -1] / 8;
    Ix = imfilter(I, hx);
    Iy = imfilter(I, hx.');
    lissage = fspecial('gaussian', 5, 1);
    Sxx = imfilter(Ix .* Ix, lissage);
    Syy = imfilter(Iy .* Iy, lissage);
    Sxy = imfilter(Ix .* Iy, lissage);
    k = 0.04;
    R = (Sxx .* Syy - Sxy .^ 2) - k * (Sxx + Syy) .^ 2;
    seuil = qualiteMin * max(R(:));
    positions = [];
    reponses = [];
    [h, l] = size(R);
    for i = 2:h-1
        for j = 2:l-1
            v = R(i, j);
            if v <= seuil
                continue;
            end
            voisinage = R(i-1:i+1, j-1:j+1);
            if v >= max(voisinage(:))
                positions(end+1, :) = [j i];
                reponses(end+1, 1) = v;
            end
        end
    end
end
