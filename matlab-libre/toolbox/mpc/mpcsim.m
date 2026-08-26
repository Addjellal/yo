function [y, u, t] = mpcsim(controleur, consigne, nPas)
%MPCSIM Simulation en boucle fermée du contrôleur prédictif.
    A = controleur.A;
    B = controleur.B;
    C = controleur.C;
    x = zeros(size(A, 1), 1);
    y = zeros(nPas, 1);
    u = zeros(nPas, 1);
    for k = 1:nPas
        y(k) = C * x;
        u(k) = mpcmove(controleur, x, consigne);
        x = A * x + B * u(k);
    end
    t = (0:nPas-1).';
end
