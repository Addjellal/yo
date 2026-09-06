function v = tform2trvec(T)
%TFORM2TRVEC Translation contenue dans une matrice homogène.
%   V = TFORM2TRVEC(T) rend les trois premières lignes de la dernière
%   colonne, sous forme de vecteur ligne.
%
%   Avec TFORM2ROTM, elle décompose une transformation : T se recompose
%   exactement en TRVEC2TFORM(V) * ROTM2TFORM(R), dans cet ordre — la
%   rotation d'abord, puis la translation.
%
%   Exemple :
%      T = trvec2tform([1 2 3]) * rotm2tform(rotz(30));
%      tform2trvec(T)                  % [1 2 3]
%
%   Voir aussi TRVEC2TFORM, TFORM2ROTM.
    v = T(1:3, 4).';
end
