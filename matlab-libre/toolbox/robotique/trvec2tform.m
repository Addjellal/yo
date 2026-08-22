function T = trvec2tform(v)
%TRVEC2TFORM Vecteur de translation vers matrice homogène 4x4.
    T = eye(4);
    T(1:3, 4) = v(:);
end
