function T = dhTransform(a, alpha, d, theta)
%DHTRANSFORM Matrice de passage de Denavit-Hartenberg.
%   T = DHTRANSFORM(A,ALPHA,D,THETA) avec la convention standard :
%   rotation THETA autour de z, translation D selon z, translation A selon
%   x, rotation ALPHA autour de x.
%
%   Exemple :
%      T = dhTransform(1, 0, 0, 0);
%      T(1, 4)                     % 1 : une translation d'un metre le long de x
%
%   Voir aussi FKINE2R, IKINE2R.
    ct = cos(theta); st = sin(theta);
    ca = cos(alpha); sa = sin(alpha);
    T = [ct, -st*ca,  st*sa, a*ct;
         st,  ct*ca, -ct*sa, a*st;
          0,     sa,     ca,    d;
          0,      0,      0,    1];
end
