function [amplitude, direction] = imgradient(a, b)
%IMGRADIENT Amplitude et direction du gradient.
%   [G,DIR] = IMGRADIENT(I) ou IMGRADIENT(GX,GY). La direction est en
%   degrés, comptée depuis l'axe des x, positive dans le sens
%   trigonométrique.
%
%   Exemple :
%      [amplitude, direction] = imgradient(repmat((1:10), 10, 1));
%      abs(mean(mean(direction(2:9, 2:9)))) < 1e-9   % la pente est horizontale
    if nargin == 2 && isnumeric(b) && ~ischar(b)
        gx = a; gy = b;
    elseif nargin == 2
        [gx, gy] = imgradientxy(a, b);
    else
        [gx, gy] = imgradientxy(a);
    end
    amplitude = sqrt(gx.^2 + gy.^2);
    direction = atan2d(-gy, gx);
end
