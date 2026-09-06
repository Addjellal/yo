function R = rotx(angle)
%ROTX Rotation autour de l'axe x, angle en degrés.
%   R = ROTX(ANGLE) rend la matrice 3x3 de la rotation d'ANGLE degrés
%   autour de l'axe x, dans le sens direct — la règle de la main droite.
%
%   Les degrés, non les radians : c'est la convention de MATLAB pour ces
%   trois fonctions, et elle diffère de celle d'EUL2ROTM. Les confondre
%   donne un résultat qui a l'air d'une rotation et n'est pas la bonne.
%
%   Le résultat est orthogonal de déterminant un, à la précision machine.
%
%   Exemple :
%      rotx(90)
%      rotx(30) * rotx(60)             % rotx(90) : les angles s'ajoutent
%
%   Voir aussi ROTY, ROTZ, EUL2ROTM, AXANG2ROTM.
    t = angle * pi / 180;
    R = [1 0 0; 0 cos(t) -sin(t); 0 sin(t) cos(t)];
end
