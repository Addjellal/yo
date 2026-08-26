function [u, v] = opticalFlowLK(I1, I2, fenetre)
%OPTICALFLOWLK Flot optique par la méthode de Lucas-Kanade.
%   [U,V] = OPTICALFLOWLK(I1,I2) rend les deux composantes du déplacement
%   estimé en chaque pixel.
    if nargin < 3
        fenetre = 5;
    end
    I1 = double(I1);
    I2 = double(I2);
    hx = [1 0 -1; 2 0 -2; 1 0 -1] / 8;
    Ix = imfilter(I1, hx);
    Iy = imfilter(I1, hx.');
    It = I2 - I1;
    [h, l] = size(I1);
    r = floor(fenetre / 2);
    u = zeros(h, l);
    v = zeros(h, l);
    for i = 1+r:h-r
        for j = 1+r:l-r
            a = Ix(i-r:i+r, j-r:j+r);
            b = Iy(i-r:i+r, j-r:j+r);
            c = It(i-r:i+r, j-r:j+r);
            A = [a(:), b(:)];
            d = -c(:);
            M = A.' * A;
            if abs(det(M)) > 1e-8
                sol = M \ (A.' * d);
                u(i, j) = sol(1);
                v(i, j) = sol(2);
            end
        end
    end
end
