function Z = sparam2zparam(S, Z0)
%SPARAM2ZPARAM Paramètres S d'un quadripôle vers paramètres Z.
    if nargin < 2
        Z0 = 50;
    end
    I = eye(2);
    Z = Z0 * (I + S) / (I - S);
end
