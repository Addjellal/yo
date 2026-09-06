function R = rotz(angle)
%ROTZ Rotation autour de l'axe z, angle en degrés.
%   R = ROTZ(ANGLE) rend la matrice 3x3 de la rotation d'ANGLE degrés
%   autour de l'axe z, dans le sens direct — la règle de la main droite.
%
%   Les degrés, non les radians : c'est la convention de MATLAB pour ces
%   trois fonctions, et elle diffère de celle d'EUL2ROTM. Les confondre
%   donne un résultat qui a l'air d'une rotation et n'est pas la bonne.
%
%   Le résultat est orthogonal de déterminant un, à la précision machine.
%
%   Exemple :
%      rotz(90)
%      rotz(30) * rotz(60)             % rotz(90) : les angles s'ajoutent
%
%   Voir aussi ROTX, ROTY, EUL2ROTM, AXANG2ROTM.
    t = angle * pi / 180;
    R = [cos(t) -sin(t) 0; sin(t) cos(t) 0; 0 0 1];
end
