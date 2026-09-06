function [u, sequence] = mpcmove(controleur, x, consigne)
%MPCMOVE Commande optimale à appliquer à l'instant courant.
%   [U,SEQUENCE] = MPCMOVE(CONTROLEUR,X,CONSIGNE) rend la commande à
%   appliquer maintenant, et la séquence entière qu'elle inaugure.
%
%   Seul U sert : la séquence est recalculée au pas suivant, avec l'état
%   mesuré et non prédit. C'est ce rejet permanent qui distingue la
%   commande prédictive d'une commande en boucle ouverte optimisée une
%   fois pour toutes.
%
%   Regarder SEQUENCE reste instructif : elle montre ce que le contrôleur
%   compte faire, et l'écart entre ce plan et ce qu'il fait vraiment
%   mesure ce que la rétroaction corrige.
%
%   Exemple :
%      x = [0; 0];
%      for k = 1:100
%          u = mpcmove(ctrl, x, 1);
%          x = A * x + B * u;
%      end
%
%   Voir aussi MPCSETUP, MPCSIM.
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
