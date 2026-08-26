function R = tform2rotm(T)
%TFORM2ROTM Rotation contenue dans une matrice homogène.
    R = T(1:3, 1:3);
end
