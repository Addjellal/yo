function y = beamformerDAS(signaux, d, theta)
%BEAMFORMERDAS Formation de voies par retard et somme.
%   SIGNAUX est une matrice éléments x échantillons.
    n = size(signaux, 1);
    a = steeringVector(n, d, theta);
    y = (a' * signaux).' / n;
end
