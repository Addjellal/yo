function [r1, r2, r3] = dcm2angle(dcm)
%DCM2ANGLE Matrice de cosinus directeurs vers angles d'Euler ZYX.
%   [R1,R2,R3] = DCM2ANGLE(DCM) rend le lacet, le tangage et le roulis, en
%   radians. C'est la réciproque d'ANGLE2DCM.
%
%   Au tangage de plus ou moins quatre-vingt-dix degrés, lacet et roulis
%   ne sont plus séparément déterminés : c'est le blocage de cardan, une
%   propriété des angles d'Euler et non un défaut de la conversion. Les
%   quaternions n'ont pas ce défaut, ce qui explique leur emploi en
%   navigation inertielle.
%
%   Exemple :
%      [r1, r2, r3] = dcm2angle(angle2dcm(0.3, 0.2, 0.1));
%      [r1 r2 r3]                          % [0.3 0.2 0.1]
%
%   Voir aussi ANGLE2DCM, ROTM2EUL, ROTM2QUAT.
    r1 = atan2(dcm(1,2), dcm(1,1));
    r2 = -asin(max(min(dcm(1,3), 1), -1));
    r3 = atan2(dcm(2,3), dcm(3,3));
end
