function r = rangefilt(image, voisinage)
%RANGEFILT Étendue locale : maximum moins minimum du voisinage.
%   Les bords sont complétés par symétrie, comme dans MATLAB : une image
%   constante a donc une étendue nulle partout, bords compris.
%
%   Exemple :
%      rangefilt([1 2; 3 4])(1, 1)   % 3
    if nargin < 2, voisinage = ones(3); end
    n = sum(sum(logical(voisinage)));
    haut = ordfilt2(image, n, voisinage, 'symmetric');
    bas = ordfilt2(image, 1, voisinage, 'symmetric');
    r = haut - bas;
end
