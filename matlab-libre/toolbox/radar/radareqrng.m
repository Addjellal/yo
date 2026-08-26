function R = radareqrng(lambda, Pt, G, sigma, Pmin)
%RADAREQRNG Portée maximale d'un radar, en mètres.
%   R = RADAREQRNG(LAMBDA,PT,G,SIGMA,PMIN) applique
%   R = ((Pt G^2 lambda^2 sigma) / ((4 pi)^3 Pmin))^(1/4).
    R = ((Pt .* G .^ 2 .* lambda .^ 2 .* sigma) ./ ((4 * pi) ^ 3 .* Pmin)) .^ 0.25;
end
