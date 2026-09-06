function R = tform2rotm(T)
%TFORM2ROTM Rotation contenue dans une matrice homogène.
%   R = TFORM2ROTM(T) rend le bloc 3x3 supérieur gauche.
%
%   La fonction ne vérifie pas que ce bloc est bien une rotation : sur une
%   transformation qui porterait un changement d'échelle ou un
%   cisaillement, elle rendrait ce bloc tel quel.
%
%   Exemple :
%      T = trvec2tform([1 2 3]) * rotm2tform(rotz(30));
%      tform2rotm(T) - rotz(30)        % 0
%
%   Voir aussi ROTM2TFORM, TFORM2TRVEC, TFORM2EUL.
    R = T(1:3, 1:3);
end
