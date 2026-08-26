function [phi, bruit, constante] = arfit(y, p)
%ARFIT Estimation d'un modèle autorégressif par Yule-Walker.
%   [PHI,SIGMA2,C] = ARFIT(Y,P) rend les coefficients, la variance du
%   bruit et la constante.
    y = y(:);
    m = mean(y);
    z = y - m;
    rho = autocorr(z, p);
    R = zeros(p, p);
    for i = 1:p
        for j = 1:p
            R(i, j) = rho(abs(i - j) + 1);
        end
    end
    phi = R \ rho(2:p+1);
    variance = var(z);
    bruit = variance * (1 - phi.' * rho(2:p+1));
    constante = m * (1 - sum(phi));
end
