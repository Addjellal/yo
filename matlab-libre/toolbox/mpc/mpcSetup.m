function controleur = mpcSetup(A, B, C, horizonPrediction, horizonCommande, Q, R)
%MPCSETUP Prépare un contrôleur prédictif à horizon fuyant.
%   Le problème résolu à chaque pas est
%      min sum ||y(k) - r||^2 Q + ||du(k)||^2 R
%   sur l'horizon de prédiction, la commande étant maintenue constante
%   au-delà de l'horizon de commande.
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
