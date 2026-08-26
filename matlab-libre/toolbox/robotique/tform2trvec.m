function v = tform2trvec(T)
%TFORM2TRVEC Translation contenue dans une matrice homogène.
    v = T(1:3, 4).';
end
