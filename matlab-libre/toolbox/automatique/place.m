function K = place(A, B, poles)
%PLACE Placement de pôles par la formule d'Ackermann.
%   K = PLACE(A,B,POLES) rend le retour d'état u = -Kx qui place les
%   valeurs propres de A-BK aux valeurs demandées (entrée unique).
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
