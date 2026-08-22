function [u, sequence] = mpcmove(controleur, x, consigne)
%MPCMOVE Commande optimale à appliquer à l'instant courant.
    p = controleur.p;
    m = controleur.m;
    r = consigne * ones(p, 1);
    F = controleur.F;
    Phi = controleur.Phi;
    Q = controleur.Q * eye(p);
    R = controleur.R * eye(m);
    H = Phi.' * Q * Phi + R;
    g = Phi.' * Q * (F * x(:) - r);
    sequence = -H \ g;
    sequence = max(min(sequence, controleur.umax), controleur.umin);
    u = sequence(1);
end
