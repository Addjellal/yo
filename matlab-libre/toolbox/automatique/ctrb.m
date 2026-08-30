function M = ctrb(A, B)
%CTRB Matrice de commandabilité.
%   M = CTRB(A,B) rend [B AB A^2B ... A^(n-1)B]. Le système est
%   commandable — on peut mener l'état où l'on veut — si et seulement si
%   cette matrice est de rang plein.
%
%   M = CTRB(SYS) prend les matrices du modèle.
%
%   Exemples :
%      rank(ctrb([0 1; 0 0], [0; 1]))       % 2 : commandable
%      rank(ctrb([1 0; 0 2], [1; 0]))       % 1 : le second etat ne bouge pas
%      size(ctrb(ss(-1, 1, 1, 0)))          % 1  1
%
%   Voir aussi OBSV, CTRBF, GRAM, MINREAL, RANK.
    if nargin == 1
        s = ss(A);
        B = s.B;
        A = s.A;
    end
    n = size(A, 1);
    M = B;
    courant = B;
    for k = 2:n
        courant = A * courant;
        M = [M, courant];
    end
end
