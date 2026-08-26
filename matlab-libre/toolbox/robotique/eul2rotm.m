function R = eul2rotm(eul)
%EUL2ROTM Angles d'Euler ZYX (radians) vers matrice de rotation.
    z = eul(1); y = eul(2); x = eul(3);
    Rz = [cos(z) -sin(z) 0; sin(z) cos(z) 0; 0 0 1];
    Ry = [cos(y) 0 sin(y); 0 1 0; -sin(y) 0 cos(y)];
    Rx = [1 0 0; 0 cos(x) -sin(x); 0 sin(x) cos(x)];
    R = Rz * Ry * Rx;
end
