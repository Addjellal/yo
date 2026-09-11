function y = im2uint16(x)
%IM2UINT16 Convertit une image en uint16 (0 à 65535).
%   Y = IM2UINT16(X) met une image flottante de [0,1] à l'échelle des
%   entiers sur seize bits. Ce qui sort de [0,1] est écrêté, non mis à
%   l'échelle. Une image UINT8 est remontée sur toute la plage, de sorte
%   que le blanc reste le blanc.
%
%   Seize bits valent 65536 niveaux au lieu de 256 : la conversion depuis
%   UINT8 n'ajoute aucune information, mais elle n'en perd pas non plus,
%   et l'aller-retour revient exactement — c'est ce qui la rend sûre pour
%   un calcul intermédiaire.
%
%   Exemple :
%      im2uint16([0 0.5 1])                   % [0 32768 65535]
%      im2uint16(uint8(255)) == 65535         % le blanc reste blanc
%      im2uint8(im2uint16(uint8(42))) == 42   % l'aller-retour est exact
%
%   Voir aussi IM2UINT8, IM2DOUBLE, IM2SINGLE, IMWRITE.
    if isa(x, 'uint16')
        y = x;
    elseif islogical(x)
        y = uint16(x) * 65535;
    elseif isa(x, 'uint8')
        % 255 doit devenir 65535, non 65280 : on multiplie par 65535/255,
        % qui vaut exactement 257.
        y = uint16(x) * 257;
    else
        y = uint16(round(max(0, min(1, double(x))) * 65535));
    end
end
