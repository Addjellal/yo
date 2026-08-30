function W = gram(systeme, type)
%GRAM Grammiens de commandabilité et d'observabilité.
%   W = GRAM(SYS,'c') résout A*W + W*A' + B*B' = 0 : le grammien de
%   commandabilité, qui mesure l'énergie qu'il faut pour atteindre chaque
%   direction de l'état.
%
%   W = GRAM(SYS,'o') résout A'*W + W*A + C'*C = 0 : le grammien
%   d'observabilité, qui mesure l'énergie que chaque direction envoie
%   dans la sortie.
%
%   Les directions que les deux grammiens ignorent sont celles qu'on peut
%   retirer du modèle : c'est le principe de la réduction équilibrée.
%
%   Exemples :
%      gram(ss(-1, 1, 1, 0), 'c')           % 0.5
%      gram(ss(-1, 1, 1, 0), 'o')           % 0.5
%      det(gram(ss([-1 0; 0 -2], eye(2), eye(2), zeros(2)), 'c')) > 0
%
%   Voir aussi CTRB, OBSV, BALREAL, HSVD, LYAP.
    if nargin < 2, type = 'c'; end
    a = systeme.A;
    if strncmpi(type, 'c', 1)
        Q = systeme.B * systeme.B';
        W = lyap(a, Q);
    else
        Q = systeme.C' * systeme.C;
        W = lyap(a', Q);
    end
end
