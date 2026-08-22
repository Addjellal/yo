function y = imgaussfilt(x, sigma)
%IMGAUSSFILT Lissage gaussien d'une image.
    if nargin < 2
        sigma = 0.5;
    end
    n = 2 * ceil(2 * sigma) + 1;
    h = fspecial('gaussian', n, sigma);
    y = imfilter(x, h);
end
