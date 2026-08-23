function lab = xyz2lab(xyz, varargin)
%XYZ2LAB Passage de XYZ à L*a*b*.
%   Le blanc de référence est le D65 par défaut ; l'option 'WhitePoint'
%   en choisit un autre.
%
%   Exemple :
%      xyz2lab(whitepoint('d65'))   % [100 0 0], le blanc parfait
    blanc = whitepoint('d65');
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'WhitePoint')
            blanc = varargin{k + 1};
            if ischar(blanc) || isstring(blanc), blanc = whitepoint(blanc); end
        end
    end
    xyz = double(xyz);
    d = size(xyz);
    liste = reshape(xyz, [], 3);
    normalise = liste ./ repmat(blanc(:)', size(liste, 1), 1);
    f = fonctionLab(normalise);
    L = 116 * f(:, 2) - 16;
    a = 500 * (f(:, 1) - f(:, 2));
    b = 200 * (f(:, 2) - f(:, 3));
    lab = reshape([L a b], d);
end

function y = fonctionLab(t)
%FONCTIONLAB Racine cubique, prolongée par une droite près de zéro.
    seuil = (6 / 29) ^ 3;
    y = zeros(size(t));
    grand = t > seuil;
    y(grand) = t(grand) .^ (1/3);
    y(~grand) = t(~grand) / (3 * (6/29) ^ 2) + 4 / 29;
end
