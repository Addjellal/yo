function R = roty(angle)
%ROTY Rotation autour de l'axe y, angle en degrés.
%   R = ROTY(ANGLE) rend la matrice 3x3 de la rotation d'ANGLE degrés
%   autour de l'axe y, dans le sens direct — la règle de la main droite.
%
%   Les degrés, non les radians : c'est la convention de MATLAB pour ces
%   trois fonctions, et elle diffère de celle d'EUL2ROTM. Les confondre
%   donne un résultat qui a l'air d'une rotation et n'est pas la bonne.
%
%   Le résultat est orthogonal de déterminant un, à la précision machine.
%
%   Exemple :
%      roty(90)
%      roty(30) * roty(60)             % roty(90) : les angles s'ajoutent
%
%   Voir aussi ROTX, ROTZ, EUL2ROTM, AXANG2ROTM.
    t = angle * pi / 180;
    R = [cos(t) 0 sin(t); 0 1 0; -sin(t) 0 cos(t)];
end
