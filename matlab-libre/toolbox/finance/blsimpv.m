function sigma = blsimpv(S, K, r, T, prix, q)
%BLSIMPV Volatilité implicite, par dichotomie sur BLSPRICE.
    if nargin < 6
        q = 0;
    end
    bas = 1e-6;
    haut = 5;
    for k = 1:200
        milieu = (bas + haut) / 2;
        c = blsprice(S, K, r, T, milieu, q);
        if c < prix
            bas = milieu;
        else
            haut = milieu;
        end
    end
    sigma = (bas + haut) / 2;
end
