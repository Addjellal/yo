function g = rgb2gray(rgb)
%RGB2GRAY Luminance d'une image couleur.
%   G = RGB2GRAY(RGB) applique la pondération de la recommandation
%   ITU-R BT.601 : 0.2989 R + 0.5870 V + 0.1140 B.
    if ndims(rgb) < 3
        g = rgb;
        return;
    end
    x = im2double(rgb);
    g = 0.2989 * x(:,:,1) + 0.5870 * x(:,:,2) + 0.1140 * x(:,:,3);
end
