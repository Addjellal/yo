function J = matlibre_deplacer_image(I, u, v)
%MATLIBRE_DEPLACER_IMAGE Recale une image sur un champ de déplacement.
%   J = MATLIBRE_DEPLACER_IMAGE(I,U,V) rend l'image dont le pixel (y,x)
%   vaut I(y+V(y,x), x+U(y,x)), interpolée linéairement. Les coordonnées
%   qui sortent du cadre sont ramenées au bord : la comparaison reste
%   possible partout.
%
%   Exemple :
%      J = matlibre_deplacer_image([1 2 3; 4 5 6], ones(2, 3), zeros(2, 3));
%      J(1, 1)   % 2
%
%   Voir aussi OPTICALFLOWFARNEBACK, INTERP2.
    I = double(I);
    [h, l] = size(I);
    [X, Y] = meshgrid(1:l, 1:h);
    Xq = min(max(X + u, 1), l);
    Yq = min(max(Y + v, 1), h);
    J = interp2(X, Y, I, Xq, Yq, 'linear');
    manquants = isnan(J);
    if any(manquants(:))
        J(manquants) = I(manquants);
    end
end
