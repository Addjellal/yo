function r = ycbcr2rgb(image)
%YCBCR2RGB Luminance et chrominances vers RVB.
%   RGB = YCBCR2RGB(YCBCR) convertit depuis l'espace de la télévision et
%   de la compression : Y la luminance, Cb et Cr les deux différences de
%   couleur.
%
%   La séparation n'est pas décorative : l'œil est bien plus sensible à la
%   luminance qu'à la chrominance, si bien que JPEG et la vidéo
%   sous-échantillonnent Cb et Cr sans que cela se voie. C'est là que la
%   moitié du gain de compression se fait.
%
%   Une entrée entière est traitée dans les plages de la vidéo — 16 à 235
%   pour Y, 16 à 240 pour Cb et Cr — et une entrée flottante dans [0,1].
%
%   Exemple :
%      ycbcr2rgb([1 0.5 0.5])          % blanc : chrominance neutre
%
%   Voir aussi RGB2YCBCR, NTSC2RGB, LAB2RGB.
    estEntier = isa(image, 'uint8');
    x = im2double(image);
    Y = x(:, :, 1) * 255; Cb = x(:, :, 2) * 255; Cr = x(:, :, 3) * 255;
    R = 255 / 219 * (Y - 16) + 255 / 224 * 1.402 * (Cr - 128);
    G = 255 / 219 * (Y - 16) - 255 / 224 * 1.772 * 0.114 / 0.587 * (Cb - 128) ...
        - 255 / 224 * 1.402 * 0.299 / 0.587 * (Cr - 128);
    B = 255 / 219 * (Y - 16) + 255 / 224 * 1.772 * (Cb - 128);
    r = cat(3, R, G, B) / 255;
    r = min(max(r, 0), 1);
    if estEntier, r = im2uint8(r); end
end
