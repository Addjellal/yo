function y = gauss2mf(x, params)
%GAUSS2MF Deux demi-gaussiennes raccordées par un plateau.
%   Y = GAUSS2MF(X,[S1 C1 S2 C2]) : montée gaussienne jusqu'à C1, plateau
%   à 1 entre C1 et C2, descente gaussienne après C2.
    s1 = params(1); c1 = params(2);
    s2 = params(3); c2 = params(4);
    x = double(x);
    gauche = ones(size(x));
    droite = ones(size(x));
    avant = x < c1;
    apres = x > c2;
    gauche(avant) = exp(-(x(avant) - c1).^2 ./ (2 * s1^2));
    droite(apres) = exp(-(x(apres) - c2).^2 ./ (2 * s2^2));
    y = gauche .* droite;
end
