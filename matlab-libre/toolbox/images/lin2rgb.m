function v = lin2rgb(u, varargin)
%LIN2RGB Applique la correction gamma de sRGB.
%   Réciproque exacte de RGB2LIN.
%
%   Exemple :
%      lin2rgb(0.214)   % 0.4999
    u = im2double(u);
    seuil = 0.0031308;
    v = zeros(size(u));
    bas = u <= seuil;
    v(bas) = 12.92 * u(bas);
    v(~bas) = 1.055 * u(~bas) .^ (1 / 2.4) - 0.055;
end
