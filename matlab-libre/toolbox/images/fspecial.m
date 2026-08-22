function h = fspecial(genre, parametre, sigma)
%FSPECIAL Noyaux de filtrage usuels.
%   H = FSPECIAL('average',N)      moyenne N x N
%   H = FSPECIAL('gaussian',N,SIG) gaussienne
%   H = FSPECIAL('sobel')          gradient vertical
%   H = FSPECIAL('prewitt')        gradient vertical
%   H = FSPECIAL('laplacian')      laplacien
%   H = FSPECIAL('log',N,SIG)      laplacien de gaussienne
    if nargin < 2, parametre = 3; end
    if nargin < 3, sigma = 0.5; end
    switch lower(char(genre))
        case 'average'
            n = parametre;
            h = ones(n, n) / (n * n);
        case 'gaussian'
            n = parametre;
            if numel(n) == 1
                n = [n n];
            end
            [X, Y] = meshgrid(-(n(2)-1)/2:(n(2)-1)/2, -(n(1)-1)/2:(n(1)-1)/2);
            h = exp(-(X.^2 + Y.^2) / (2 * sigma^2));
            h = h / sum(h(:));
        case 'sobel'
            h = [1 2 1; 0 0 0; -1 -2 -1];
        case 'prewitt'
            h = [1 1 1; 0 0 0; -1 -1 -1];
        case 'laplacian'
            h = [0 1 0; 1 -4 1; 0 1 0];
        case 'log'
            n = parametre;
            [X, Y] = meshgrid(-(n-1)/2:(n-1)/2, -(n-1)/2:(n-1)/2);
            r2 = X.^2 + Y.^2;
            h = (r2 - 2*sigma^2) .* exp(-r2 / (2*sigma^2)) / (2*pi*sigma^6);
            h = h - mean(h(:));
        otherwise
            error('images:fspecial:unknownType', 'Unknown filter type ''%s''.', genre);
    end
end
