function g = arrayGain(n, d, theta, theta0)
%ARRAYGAIN Gain d'un réseau pointé dans une direction.
%   G = ARRAYGAIN(N,D,THETA,THETA0) rend le gain normalisé d'un réseau
%   pointé vers THETA0, pour une onde arrivant de THETA.
%
%   Le gain vaut un dans la direction visée — toute la puissance — et bien
%   moins ailleurs. Il ne peut jamais dépasser un : c'est une moyenne de
%   termes de module un.
%
%   C'est ce contraste qui sépare deux sources voisines, et son ouverture
%   se resserre comme l'inverse de la longueur du réseau. À espacement
%   d'une longueur d'onde, une autre direction est confondue avec la
%   visée : c'est l'ambiguïté spatiale.
%
%   Exemple :
%      arrayGain(8, 0.5, 0, 0)         % 1 : dans la direction visee
%      angles = linspace(-pi/2, pi/2, 3601);
%      beamwidth(angles, arrayGain(8, 0.5, angles, 0))
%
%   Voir aussi STEERINGVECTOR, BEAMFORMERDAS, MUSICSPECTRUM.
    a = steeringVector(n, d, theta);
    a0 = steeringVector(n, d, theta0);
    g = abs(a0' * a) / n;
end
