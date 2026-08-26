function M = obsv(A, C)
%OBSV Matrice d'observabilité [C; CA; CA^2; ...].
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
