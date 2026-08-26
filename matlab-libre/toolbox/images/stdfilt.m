function r = stdfilt(image, voisinage)
%STDFILT Écart-type local.
%   R = STDFILT(I,VOISINAGE) rend l'écart-type des pixels du voisinage,
%   normalisé par n-1 comme le fait MATLAB.
    if nargin < 2, voisinage = ones(3); end
    x = double(image);
    masque = double(logical(voisinage));
    n = sum(masque(:));
    if n <= 1
        r = zeros(size(x));
        return
    end
    moyenne = imfilter(x, masque / n, 'symmetric');
    carre = imfilter(x.^2, masque / n, 'symmetric');
    variance = max(carre - moyenne.^2, 0) * n / (n - 1);
    r = sqrt(variance);
end
