function r = entropyfilt(image, voisinage)
%ENTROPYFILT Entropie locale, en bits.
%   L'histogramme est calculé sur 256 niveaux, comme dans MATLAB.
    if nargin < 2, voisinage = ones(9); end
    x = double(image);
    if max(x(:)) <= 1, x = x * 255; end
    x = round(min(max(x, 0), 255));
    [m, n] = size(x);
    [dm, dn] = size(voisinage);
    di = floor(dm / 2);
    dj = floor(dn / 2);
    etendu = padarray(x, [di dj], 'symmetric');
    r = zeros(m, n);
    for i = 1:m
        for j = 1:n
            bloc = etendu(i:i + dm - 1, j:j + dn - 1);
            valeurs = bloc(logical(voisinage));
            comptes = accumarray(valeurs(:) + 1, 1);
            p = comptes(comptes > 0) / numel(valeurs);
            r(i, j) = -sum(p .* log2(p));
        end
    end
end
