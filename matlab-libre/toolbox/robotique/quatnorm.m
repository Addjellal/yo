function n = quatnorm(q)
%QUATNORM Norme de quaternions au sens de MATLAB : la somme des carrés.
%   N = QUATNORM(Q) rend, pour chaque ligne de Q (M x 4), q0^2 + q1^2 +
%   q2^2 + q3^2, en colonne. Comme dans MATLAB, c'est le carré du module :
%   QUATMOD en est la racine.
%
%   Exemple :
%      quatnorm([.5 -.5 .5 0])         % 0.75, documentation de MATLAB
%
%   Voir aussi QUATMOD, QUATNORMALIZE, QUATINV.
    if size(q, 2) ~= 4
        error('aero:quatnorm:Taille', 'Quaternions must be rows [w x y z]: M-by-4.');
    end
    n = sum(double(q) .^ 2, 2);
end
