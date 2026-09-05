function r = quatdivide(q, p)
%QUATDIVIDE Division de quaternions.
%   R = QUATDIVIDE(Q,P) rend Q * inv(P).
%
%   La multiplication des quaternions n'est pas commutative : diviser à
%   droite et diviser à gauche ne donnent pas le même résultat. C'est la
%   division à droite qui est rendue ici, comme dans MATLAB.
%
%   Exemple :
%      q = eul2quat([0.3 0.2 0.1]);
%      quatdivide(q, q)                % [1 0 0 0]
%
%   Voir aussi QUATMULTIPLY, QUATINV, QUATCONJ.
    r = quatmultiply(q, quatinv(p));
end
