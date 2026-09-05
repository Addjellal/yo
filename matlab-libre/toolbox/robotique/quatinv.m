function r = quatinv(q)
%QUATINV Inverse d'un quaternion.
%   R = QUATINV(Q) rend le quaternion qui, multiplié par Q, donne
%   l'identité [1 0 0 0] :
%
%      inv(q) = conj(q) / |q|^2
%
%   Pour un quaternion unitaire — le seul cas qui décrive une rotation —
%   l'inverse est donc le conjugué, et inverser une rotation revient à
%   changer le signe de sa partie imaginaire.
%
%   Exemple :
%      q = eul2quat([0.3 0.2 0.1]);
%      quatmultiply(q, quatinv(q))     % [1 0 0 0]
%
%   Voir aussi QUATCONJ, QUATMULTIPLY, QUATDIVIDE, QUATNORMALIZE.
    [m, unique] = matlibre_rob_lignes(q, 4, 'Q');
    n = size(m, 1);
    r = zeros(n, 4);
    for k = 1:n
        carre = sum(m(k, :) .^ 2);
        if carre < eps
            error('robotics:quatinv:Nul', ...
                  'Un quaternion nul n''a pas d''inverse.');
        end
        r(k, :) = [m(k, 1), -m(k, 2:4)] / carre;
    end
    if unique
        r = r(1, :);
    end
end
