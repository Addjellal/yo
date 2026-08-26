function [r1, r2, r3] = dcm2angle(dcm)
%DCM2ANGLE Matrice de cosinus directeurs vers angles d'Euler ZYX.
    r1 = atan2(dcm(1,2), dcm(1,1));
    r2 = -asin(max(min(dcm(1,3), 1), -1));
    r3 = atan2(dcm(2,3), dcm(3,3));
end
