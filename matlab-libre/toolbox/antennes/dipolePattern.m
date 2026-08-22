function E = dipolePattern(theta, longueurOnde)
%DIPOLEPATTERN Diagramme de rayonnement d'un dipôle de longueur L/lambda.
%   E = DIPOLEPATTERN(THETA,L) où THETA est en radians et L la longueur
%   rapportée à la longueur d'onde (0.5 pour un demi-onde).
    if nargin < 2
        longueurOnde = 0.5;
    end
    kl = pi * longueurOnde;
    E = zeros(size(theta));
    for k = 1:numel(theta)
        s = sin(theta(k));
        if abs(s) < 1e-12
            E(k) = 0;
        else
            E(k) = abs((cos(kl * cos(theta(k))) - cos(kl)) / s);
        end
    end
end
