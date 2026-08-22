function y = imnoise(x, genre, parametre)
%IMNOISE Ajoute du bruit à une image.
%   Y = IMNOISE(X,'gaussian',VAR) ajoute un bruit blanc gaussien.
%   Y = IMNOISE(X,'salt & pepper',D) remplace une fraction D des pixels.
    x = im2double(x);
    if nargin < 2, genre = 'gaussian'; end
    if nargin < 3, parametre = 0.01; end
    switch lower(char(genre))
        case 'gaussian'
            y = x + sqrt(parametre) * randn(size(x));
        case {'salt & pepper', 'salt', 'saltpepper'}
            y = x;
            masque = rand(size(x));
            y(masque < parametre / 2) = 0;
            y(masque > 1 - parametre / 2) = 1;
        case 'speckle'
            y = x + x .* (sqrt(parametre) * randn(size(x)));
        otherwise
            error('images:imnoise:unknownType', 'Unknown noise type.');
    end
    y = max(0, min(1, y));
end
