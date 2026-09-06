function e = immse(a, b)
%IMMSE Erreur quadratique moyenne entre deux images.
%   E = IMMSE(A,B) rend la moyenne des carrés des écarts, pixel à pixel.
%
%   Elle vaut zéro pour deux images identiques et croît avec l'écart. Elle
%   ne dit rien de la ressemblance perçue : deux images d'erreur
%   quadratique égale peuvent être l'une très acceptable et l'autre
%   inregardable, selon que l'erreur est répartie ou concentrée. C'est ce
%   que les mesures perceptuelles — SSIM — cherchent à corriger.
%
%   Le rapport signal à bruit de crête s'en déduit : PSNR = 10 log10(1/E)
%   pour des images dans [0,1].
%
%   Exemple :
%      immse(ones(4), ones(4))         % 0
%      immse(zeros(4), ones(4))        % 1
%
%   Voir aussi PSNR, SSIM, IMABSDIFF.
    a = double(a);
    b = double(b);
    d = a(:) - b(:);
    e = sum(d.^2) / numel(d);
end
