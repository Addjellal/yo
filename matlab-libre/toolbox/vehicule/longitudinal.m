function acceleration = longitudinal(force, masse, vitesse, cx, surface, rho, crr, pente)
%LONGITUDINAL Accélération longitudinale avec résistances.
    if nargin < 5, surface = 2.2; end
    if nargin < 6, rho = 1.225; end
    if nargin < 7, crr = 0.012; end
    if nargin < 8, pente = 0; end
    g = 9.81;
    trainee = 0.5 * rho * cx * surface * vitesse ^ 2;
    roulement = crr * masse * g * cos(pente);
    gravite = masse * g * sin(pente);
    acceleration = (force - trainee - roulement - gravite) / masse;
end
