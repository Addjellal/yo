function T = rotm2tform(R)
%ROTM2TFORM Rotation vers matrice homogène.
    T = eye(4);
    T(1:3, 1:3) = R;
end
