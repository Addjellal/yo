function dcm = angle2dcm(r1, r2, r3, ordre)
%ANGLE2DCM Angles d'Euler (radians) vers matrice de cosinus directeurs.
%   DCM = ANGLE2DCM(R1,R2,R3) rend la matrice qui passe du repère de
%   référence au repère du mobile, dans l'ordre ZYX — lacet, tangage,
%   roulis. ANGLE2DCM(R1,R2,R3,ORDRE) emploie une autre séquence.
%
%   Attention au sens : la matrice de cosinus directeurs de
%   l'aéronautique va du repère fixe vers le repère mobile, alors que
%   EUL2ROTM rend la rotation inverse, du mobile vers le fixe. Les deux
%   sont transposées l'une de l'autre, et les confondre inverse tous les
%   signes.
%
%   Exemple :
%      dcm = angle2dcm(deg2rad(30), 0, 0);
%      [r1, r2, r3] = dcm2angle(dcm);
%      rad2deg(r1)                         % 30
%
%   Voir aussi DCM2ANGLE, EUL2ROTM, ROTM2EUL.
    if nargin < 4
        ordre = 'ZYX';
    end
    Rz = [cos(r1) sin(r1) 0; -sin(r1) cos(r1) 0; 0 0 1];
    Ry = [cos(r2) 0 -sin(r2); 0 1 0; sin(r2) 0 cos(r2)];
    Rx = [1 0 0; 0 cos(r3) sin(r3); 0 -sin(r3) cos(r3)];
    switch upper(char(ordre))
        case 'ZYX'
            dcm = Rx * Ry * Rz;
        case 'XYZ'
            dcm = Rz * Ry * Rx;
        otherwise
            dcm = Rx * Ry * Rz;
    end
end
