function eul = rotm2eul(R)
%ROTM2EUL Matrice de rotation vers angles d'Euler ZYX (radians).
    sy = sqrt(R(1,1)^2 + R(2,1)^2);
    if sy > 1e-9
        x = atan2(R(3,2), R(3,3));
        y = atan2(-R(3,1), sy);
        z = atan2(R(2,1), R(1,1));
    else
        x = atan2(-R(2,3), R(2,2));
        y = atan2(-R(3,1), sy);
        z = 0;
    end
    eul = [z y x];
end
