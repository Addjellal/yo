function r = imsharpen(image, varargin)
%IMSHARPEN Accentue les contours par masque flou.
%   R = IMSHARPEN(I,'Radius',R,'Amount',A) retranche une version floutée :
%   R = I + A*(I - flou(I)). Le rayon vaut 1 et le montant 0,8 par défaut,
%   comme dans MATLAB.
    rayon = 1;
    montant = 0.8;
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'radius', rayon = varargin{k + 1};
            case 'amount', montant = varargin{k + 1};
        end
    end
    x = double(image);
    flou = imgaussfilt(x, rayon);
    r = x + montant * (x - flou);
    if isa(image, 'uint8')
        r = im2uint8(min(max(r / 255, 0), 1));
    else
        r = min(max(r, 0), 1);
    end
end
