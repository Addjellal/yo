function M = ctrb(A, B)
%CTRB Matrice de commandabilité [B AB A^2B ...].
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
