function v = quatrotate(q, r)
%QUATROTATE Rotation d'un vecteur par un quaternion.
%   V = QUATROTATE(Q,R) applique au vecteur ligne R la rotation décrite
%   par Q.
%
%   Attention à la convention : comme dans MATLAB, la rotation appliquée
%   est celle du quaternion conjugué — c'est-à-dire que QUATROTATE fait
%   passer du repère de départ à celui qui a tourné, non l'inverse. Un
%   vecteur tourné dans le sens direct s'obtient donc par
%   QUATROTATE(QUATCONJ(Q),R), ou par QUAT2ROTM(Q) * R'.
%
%   Une matrice N sur 3 rend une matrice N sur 3.
%
%   Exemple :
%      quatrotate([cos(pi/4) 0 0 sin(pi/4)], [1 0 0])   % [0 -1 0]
%      (quat2rotm([cos(pi/4) 0 0 sin(pi/4)]) * [1;0;0]).'  % [0 1 0]
%
%   Voir aussi QUAT2ROTM, QUATMULTIPLY, QUATCONJ.
    [qm, ~] = matlibre_rob_lignes(q, 4, 'Q');
    [rm, uniqueVecteur] = matlibre_rob_lignes(r, 3, 'R');
    n = max(size(qm, 1), size(rm, 1));
    v = zeros(n, 3);
    for k = 1:n
        quaternion = qm(min(k, size(qm, 1)), :);
        vecteur = rm(min(k, size(rm, 1)), :);
        R = quat2rotm(quaternion);
        v(k, :) = (R.' * vecteur(:)).';
    end
    if uniqueVecteur && size(qm, 1) == 1
        v = v(1, :);
    end
end
