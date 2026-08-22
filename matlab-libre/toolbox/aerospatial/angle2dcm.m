function dcm = angle2dcm(r1, r2, r3, ordre)
%ANGLE2DCM Angles d'Euler (radians) vers matrice de cosinus directeurs.
%   L'ordre par défaut est ZYX, comme dans la documentation.
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
