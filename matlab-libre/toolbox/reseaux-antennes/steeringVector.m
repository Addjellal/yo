function a = steeringVector(n, d, theta)
%STEERINGVECTOR Vecteur de pointage d'un réseau linéaire uniforme.
%   N éléments espacés de D longueurs d'onde, direction THETA en radians.
    k = (0:n-1).';
    a = exp(1i * 2 * pi * d * k * sin(theta));
end
