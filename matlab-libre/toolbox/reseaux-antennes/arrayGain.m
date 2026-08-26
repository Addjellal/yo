function g = arrayGain(n, d, theta, theta0)
%ARRAYGAIN Gain d'un réseau pointé dans une direction.
    a = steeringVector(n, d, theta);
    a0 = steeringVector(n, d, theta0);
    g = abs(a0' * a) / n;
end
