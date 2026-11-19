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
%   Le critère est la somme, sur l'horizon de prédiction, de Q fois le
%   carré de l'écart à la consigne, plus R fois le carré des commandes de
%   l'horizon de commande. Avec les bornes CONTROLEUR.umin et umax, c'est
%   un programme quadratique sous contraintes, résolu exactement par
%   QUADPROG : écrêter la solution libre ne donnerait pas l'optimum, car les
%   commandes suivantes doivent compenser celles que la borne retient.
%   Sans contrainte et sur un horizon long, la première commande tend vers
%   celle du régulateur LQR de même pondération.
%
%   Exemple :
%      A = [1 0.1; 0 1]; B = [0.005; 0.1]; C = [1 0];
%      ctrl = mpcSetup(A, B, C, 20, 5, 1, 0.1);
%      x = [0; 0];
%      for k = 1:100
%          u = mpcmove(ctrl, x, 1);
%          x = A * x + B * u;
%      end
%      abs(C * x - 1) < 0.05        % 1 : la consigne est atteinte
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
    bornes = isfinite(controleur.umin) || isfinite(controleur.umax);
    if bornes
        bas = repmat(controleur.umin, m, 1);
        haut = repmat(controleur.umax, m, 1);
        [sequence, ~, drapeau] = quadprog((H + H.') / 2, g, [], [], [], [], bas, haut);
        if drapeau ~= 1
            error('mpc:mpcmove:Infaisable', ...
                  'Le programme quadratique sous contraintes n''a pas de solution admissible.');
        end
    else
        sequence = -H \ g;
    end
    u = sequence(1);
end
