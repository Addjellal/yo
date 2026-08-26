function xyz = lab2xyz(lab, varargin)
%LAB2XYZ Passage de L*a*b* à XYZ.
%   Réciproque exacte de XYZ2LAB.
    blanc = whitepoint('d65');
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'WhitePoint')
            blanc = varargin{k + 1};
            if ischar(blanc) || isstring(blanc), blanc = whitepoint(blanc); end
        end
    end
    lab = double(lab);
    d = size(lab);
    liste = reshape(lab, [], 3);
    fy = (liste(:, 1) + 16) / 116;
    fx = fy + liste(:, 2) / 500;
    fz = fy - liste(:, 3) / 200;
    t = inverseFonctionLab([fx fy fz]);
    xyz = t .* repmat(blanc(:)', size(t, 1), 1);
    xyz = reshape(xyz, d);
end

function t = inverseFonctionLab(f)
    seuil = 6 / 29;
    t = zeros(size(f));
    grand = f > seuil;
    t(grand) = f(grand) .^ 3;
    t(~grand) = 3 * seuil ^ 2 * (f(~grand) - 4 / 29);
end
