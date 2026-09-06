function controleur = mpcSetup(A, B, C, horizonPrediction, horizonCommande, Q, R)
%MPCSETUP Prépare un contrôleur prédictif à horizon fuyant.
%   Le problème résolu à chaque pas est
%      min sum ||y(k) - r||^2 Q + ||du(k)||^2 R
%   sur l'horizon de prédiction, la commande étant maintenue constante
%   au-delà de l'horizon de commande.
%
%   CONTROLEUR = MPCSETUP(A,B,C,P,M,Q,R) où (A,B,C) est le modèle discret,
%   P l'horizon de prédiction, M l'horizon de commande, Q le poids de
%   l'écart à la consigne et R celui de l'effort.
%
%   L'horizon fuyant est ce qui fait la méthode : on résout sur P pas,
%   on n'applique que le premier, et l'on recommence au pas suivant avec
%   la mesure fraîche. C'est ce qui la rend robuste malgré un modèle
%   imparfait.
%
%   Le rapport Q/R est le seul vrai réglage : Q grand suit vite la
%   consigne et sollicite les actionneurs, R grand ménage la commande et
%   suit mollement. Il n'y a pas de choix universel, seulement un
%   compromis à assumer.
%
%   Les matrices de prédiction sont calculées une fois pour toutes ici :
%   MPCMOVE n'a plus qu'à résoudre un système linéaire à chaque pas.
%
%   Exemple :
%      A = [1 0.1; 0 1]; B = [0.005; 0.1]; C = [1 0];
%      ctrl = mpcSetup(A, B, C, 20, 5, 1, 0.1);
%      [y, u] = mpcsim(ctrl, 1, 100);
%
%   Voir aussi MPCMOVE, MPCSIM.
    if nargin < 6, Q = 1; end
    if nargin < 7, R = 0.1; end
    controleur = struct();
    controleur.A = A;
    controleur.B = B;
    controleur.C = C;
    controleur.p = horizonPrediction;
    controleur.m = horizonCommande;
    controleur.Q = Q;
    controleur.R = R;
    controleur.umin = -inf;
    controleur.umax = inf;
    % Matrices de prédiction : Y = F x + Phi U
    n = size(A, 1);
    F = zeros(horizonPrediction, n);
    Phi = zeros(horizonPrediction, horizonCommande);
    puissance = eye(n);
    for i = 1:horizonPrediction
        puissance = puissance * A;
        F(i, :) = C * puissance;
        for j = 1:min(i, horizonCommande)
            bloc = eye(n);
            for k = 1:(i - j)
                bloc = bloc * A;
            end
            Phi(i, j) = C * bloc * B;
        end
    end
    controleur.F = F;
    controleur.Phi = Phi;
end
