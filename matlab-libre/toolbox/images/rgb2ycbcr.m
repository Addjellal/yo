function y = rgb2ycbcr(image)
%RGB2YCBCR Couleurs RVB vers luminance et chrominances.
%   Y = RGB2YCBCR(IMAGE) applique la matrice de la recommandation
%   ITU-R BT.601, avec les plages 16..235 et 16..240 de MATLAB pour les
%   entiers 8 bits, et les mêmes valeurs ramenées à [0,1] pour un double.
    estEntier = isa(image, 'uint8');
    x = im2double(image);
    R = x(:, :, 1); G = x(:, :, 2); B = x(:, :, 3);
    Y  =  16 / 255 +  65.481 / 255 * R + 128.553 / 255 * G +  24.966 / 255 * B;
    Cb = 128 / 255 -  37.797 / 255 * R -  74.203 / 255 * G + 112.000 / 255 * B;
    Cr = 128 / 255 + 112.000 / 255 * R -  93.786 / 255 * G -  18.214 / 255 * B;
    y = cat(3, Y, Cb, Cr);
    if estEntier, y = im2uint8(y); end
end
