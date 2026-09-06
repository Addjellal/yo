function y = im2uint8(x)
%IM2UINT8 Convertit une image en uint8 (0 à 255).
%   Y = IM2UINT8(X) multiplie une image flottante par 255 et arrondit.
%   Ce qui sort de [0,1] est écrêté, non mis à l'échelle.
%
%   La conversion perd de l'information : deux valeurs distantes de moins
%   de 1/255 deviennent identiques. C'est pourquoi on ne convertit qu'à la
%   fin, pour écrire ou pour afficher.
%
%   Exemple :
%      im2uint8([0 0.5 1])             % [0 128 255]
%      im2uint8(im2double(uint8(42)))  % 42 : l'aller-retour est exact
%
%   Voir aussi IM2DOUBLE, IMWRITE.
    if isa(x, 'uint8')
        y = x;
    elseif islogical(x)
        y = uint8(x) * 255;
    else
        y = uint8(round(max(0, min(1, double(x))) * 255));
    end
end
