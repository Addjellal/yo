function [y, u, t] = mpcsim(controleur, consigne, nPas)
%MPCSIM Simulation en boucle fermée du contrôleur prédictif.
%   [Y,U,T] = MPCSIM(CONTROLEUR,CONSIGNE,NPAS) simule NPAS pas en boucle
%   fermée depuis l'état nul, et rend la sortie, la commande et le temps.
%
%   C'est la vérification qui compte : un contrôleur prédictif bien réglé
%   rejoint la consigne sans erreur permanente, et la commande se
%   stabilise. Une commande qui oscille indique un R trop petit devant Q.
%
%   Exemple :
%      [y, u, t] = mpcsim(ctrl, 1, 100);
%      y(end)                          % 1 : la consigne est atteinte
%      max(abs(diff(u)))               % l'a-coup de commande le plus fort
%
%   Voir aussi MPCSETUP, MPCMOVE.
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
