function C = matlibre_espace_couleur(A, dejaLab)
%MATLIBRE_ESPACE_COULEUR Image ramenée à l'espace où l'on mesure.
%   C = MATLIBRE_ESPACE_COULEUR(A,DEJALAB) rend l'image en L*a*b* si elle
%   est en couleurs, ou sur un seul plan à l'échelle de L* si elle est en
%   niveaux de gris. C'est l'espace où une distance euclidienne se lit
%   comme une différence perçue, ce qui est ce que veut le regroupement.
%
%   Exemple :
%      size(matlibre_espace_couleur(zeros(4, 4, 3), false))   % 4 4 3
%
%   Voir aussi SUPERPIXELS, RGB2LAB.
    A = double(A);
    % La tolérance évite de prendre pour une image sur 0-255 une image
    % lissée dont le maximum dépasse un d'un epsilon.
    if max(A(:)) > 1 + 1e-6 && ~dejaLab
        A = A / 255;
    end
    if size(A, 3) == 3
        if dejaLab
            C = A;
        else
            C = rgb2lab(A);
        end
    else
        C = A(:, :, 1) * 100;
    end
end
