function M = obsv(A, C)
%OBSV Matrice d'observabilité.
%   M = OBSV(A,C) rend [C; CA; CA^2; ... ; CA^(n-1)]. Le système est
%   observable — l'état se reconstruit à partir de la sortie — si et
%   seulement si cette matrice est de rang plein.
%
%   M = OBSV(SYS) prend les matrices du modèle.
%
%   Exemples :
%      rank(obsv([0 1; 0 0], [1 0]))        % 2 : observable
%      rank(obsv([1 0; 0 2], [1 0]))        % 1 : le second etat reste cache
%      size(obsv(ss(-1, 1, 1, 0)))          % 1  1
%
%   Voir aussi CTRB, OBSVF, GRAM, KALMAN, RANK.
    if nargin == 1
        s = ss(A);
        C = s.C;
        A = s.A;
    end
    n = size(A, 1);
    M = C;
    courant = C;
    for k = 2:n
        courant = courant * A;
        M = [M; courant];
    end
end
