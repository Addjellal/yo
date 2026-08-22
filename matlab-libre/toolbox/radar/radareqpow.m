function Pt = radareqpow(lambda, R, G, sigma, Pmin)
%RADAREQPOW Puissance d'émission nécessaire pour une portée donnée.
    Pt = Pmin .* (4 * pi) ^ 3 .* R .^ 4 ./ (G .^ 2 .* lambda .^ 2 .* sigma);
end
