function q = dpressure(rho, vitesse)
%DPRESSURE Pression dynamique 0.5 rho V^2.
    q = 0.5 * rho .* vitesse .^ 2;
end
