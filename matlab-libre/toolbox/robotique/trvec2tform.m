function T = trvec2tform(v)
%TRVEC2TFORM Vecteur de translation vers matrice homogène 4x4.
%   T = TRVEC2TFORM([X Y Z]) rend la transformation de translation pure :
%   l'identité avec la translation dans la dernière colonne.
%
%   Les coordonnées homogènes existent pour cela : une translation n'est
%   pas linéaire en dimension trois, mais elle l'est en dimension quatre.
%   C'est ce qui permet de composer rotations et translations par un
%   simple produit de matrices.
%
%   Exemple :
%      T = trvec2tform([1 2 3]) * rotm2tform(rotz(30));
%      tform2trvec(T)                  % [1 2 3]
%
%   Voir aussi TFORM2TRVEC, ROTM2TFORM, EUL2TFORM.
    T = eye(4);
    T(1:3, 4) = v(:);
end
