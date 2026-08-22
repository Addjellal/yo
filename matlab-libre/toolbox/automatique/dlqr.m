function [K, S] = dlqr(A, B, Q, R)
%DLQR Commande linéaire quadratique en temps discret.
    S = Q;
    for k = 1:100000
        Sn = A' * S * A - (A' * S * B) / (R + B' * S * B) * (B' * S * A) + Q;
        if max(max(abs(Sn - S))) < 1e-12 * max(1, max(max(abs(S))))
            S = Sn;
            break;
        end
        S = Sn;
    end
    K = (R + B' * S * B) \ (B' * S * A);
end
