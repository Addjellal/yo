function [positions, reponses] = detectMinEigenFeatures(I, varargin)
%DETECTMINEIGENFEATURES Coins de Shi et Tomasi.
%   [P,R] = DETECTMINEIGENFEATURES(I) rend les coordonnées [x y] des coins
%   et leur réponse. Le critère est la plus petite valeur propre de la
%   matrice d'autocorrélation locale
%
%      M = [ Sxx Sxy ; Sxy Syy ]
%
%   qui vaut ((Sxx+Syy) - sqrt((Sxx-Syy)^2 + 4 Sxy^2)) / 2. Un coin est un
%   point où les deux valeurs propres sont grandes : prendre la plus
%   petite est plus direct que la combinaison de Harris, et c'est ce
%   critère qui décide des points à suivre dans un flot optique.
%
%   Options : 'MinQuality' (0.01), 'FilterSize' (5).
%
%   Exemple :
%      I = zeros(20); I(6:15, 6:15) = 1;
%      p = detectMinEigenFeatures(I);   % les quatre coins du carré
%
%   Voir aussi DETECTHARRISFEATURES, DETECTFASTFEATURES, SELECTSTRONGEST.
    qualiteMin = 0.01;
    tailleFiltre = 5;
    for k = 1:2:numel(varargin)-1
        switch lower(char(varargin{k}))
            case 'minquality',  qualiteMin = varargin{k+1};
            case 'filtersize',  tailleFiltre = varargin{k+1};
        end
    end
    I = double(I);
    if ndims(I) == 3
        I = rgb2gray(I);
    end
    hx = [1 0 -1; 2 0 -2; 1 0 -1] / 8;
    Ix = imfilter(I, hx);
    Iy = imfilter(I, hx.');
    lissage = fspecial('gaussian', tailleFiltre, tailleFiltre / 4);
    Sxx = imfilter(Ix .* Ix, lissage);
    Syy = imfilter(Iy .* Iy, lissage);
    Sxy = imfilter(Ix .* Iy, lissage);
    trace = Sxx + Syy;
    discriminant = sqrt((Sxx - Syy) .^ 2 + 4 * Sxy .^ 2);
    R = (trace - discriminant) / 2;
    [positions, reponses] = maximaLocaux(R, qualiteMin * max(R(:)));
end

function [positions, reponses] = maximaLocaux(R, seuil)
%MAXIMALOCAUX Points strictement supérieurs à leurs huit voisins.
    [h, l] = size(R);
    positions = [];
    reponses = [];
    for i = 2:h-1
        for j = 2:l-1
            v = R(i, j);
            if v <= seuil || v <= 0
                continue
            end
            voisinage = R(i-1:i+1, j-1:j+1);
            if v >= max(voisinage(:))
                positions(end+1, :) = [j, i];       %#ok<AGROW>
                reponses(end+1, 1) = v;             %#ok<AGROW>
            end
        end
    end
end
