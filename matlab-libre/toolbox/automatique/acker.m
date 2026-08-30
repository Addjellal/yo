function K = acker(A, B, poles)
%ACKER Placement de pôles par la formule d'Ackermann.
%   K = ACKER(A,B,P) rend le gain de retour d'état qui place les pôles de
%   A - B*K aux valeurs P. Le système doit avoir une seule entrée et être
%   commandable.
%
%   Pour plusieurs entrées, le placement n'est plus unique : c'est PLACE
%   qu'il faut, qui choisit alors le gain le mieux conditionné.
%
%   Exemple :
%      A = [0 1; 0 0]; B = [0; 1];
%      K = acker(A, B, [-2 -3]);
%      sort(eig(A - B*K))          % -3  -2
%
%   Voir aussi PLACE, LQR, CTRB, POLE, EIG.
    K = place(A, B, poles);
end
