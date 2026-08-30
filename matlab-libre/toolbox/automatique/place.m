function K = place(A, B, poles)
%PLACE Placement de pôles par retour d'état.
%   K = PLACE(A,B,P) rend le gain tel que les valeurs propres de A - B*K
%   soient celles de P. Pour plusieurs entrées, le gain n'est pas unique :
%   la fonction choisit celui qui rend les vecteurs propres les mieux
%   conditionnés, ce qui limite la sensibilité du placement.
%
%   Les pôles complexes doivent aller par paires conjuguées, et le
%   système être commandable.
%
%   Exemples :
%      A = [0 1; 0 0]; B = [0; 1];
%      K = place(A, B, [-1 -2]);
%      sort(eig(A - B*K))                   % -2  -1
%      K2 = place(A, B, [-1+1i, -1-1i]);
%      max(real(eig(A - B*K2))) < 0         % vrai
%
%   Voir aussi ACKER, LQR, EIG, CTRB.
    n = size(A, 1);
    Co = ctrb(A, B);
    if rank(Co) < n
        error('control:place:NotControllable', 'The pair (A,B) is not controllable.');
    end
    souhaite = real(poly(poles));
    phi = zeros(n, n);
    for k = 1:n+1
        phi = phi + souhaite(k) * A ^ (n + 1 - k);
    end
    e = zeros(1, n);
    e(n) = 1;
    K = e * (Co \ phi);
end
