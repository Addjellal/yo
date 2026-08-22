function [num, den] = ss2tf(A, B, C, D)
%SS2TF Fonction de transfert d'un modèle d'état.
%   [NUM,DEN] = SS2TF(A,B,C,D) applique la formule
%   H(s) = C (sI - A)^-1 B + D, calculée par l'algorithme de
%   Leverrier-Faddeev.
    n = size(A, 1);
    den = poly(eig(A));
    den = real(den);
    num = zeros(1, n + 1);
    % Coefficients par la méthode de Leverrier.
    M = eye(n);
    for k = 1:n+1
        num(k) = C * M * B + D * den(k);
        if k <= n
            M = A * M + den(k+1) * eye(n);
        end
    end
end
