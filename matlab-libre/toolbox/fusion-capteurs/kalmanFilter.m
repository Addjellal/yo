function [x, P] = kalmanFilter(x, P, z, A, H, Q, R, u, B)
%KALMANFILTER Un pas de filtre de Kalman linéaire (prédiction et correction).
%   [X,P] = KALMANFILTER(X,P,Z,A,H,Q,R) fait un pas complet : la
%   prédiction par le modèle A, puis la correction par la mesure Z.
%   [X,P] = KALMANFILTER(X,P,Z,A,H,Q,R,U,B) ajoute une commande connue.
%
%      X  l'état estimé          P  sa covariance
%      Z  la mesure              A  la matrice d'évolution
%      H  la matrice de mesure   Q  le bruit de modèle
%      R  le bruit de mesure     U, B la commande et son effet
%
%   Le gain K = P H' / (H P H' + R) est ce qui distingue ce filtre d'une
%   moyenne pondérée fixe : il se recalcule à chaque pas selon la
%   confiance qu'on a dans l'estimation courante face à la mesure. Quand
%   P est grand, la mesure l'emporte ; quand il est petit, le modèle.
%
%   Le filtre estime aussi ce qu'aucune mesure ne donne — une vitesse, un
%   biais de capteur — pourvu que le modèle les relie à ce qu'on mesure.
%   C'est là son intérêt principal, et il ne tient qu'à cette liaison.
%
%   Exemple :
%      A = [1 0.1; 0 1]; H = [1 0];
%      Q = diag([1e-4 1e-3]); R = 0.5;
%      x = [0; 0]; P = eye(2);
%      [x, P] = kalmanFilter(x, P, mesure, A, H, Q, R);
%
%   Voir aussi COMPLEMENTARYFILTER, EKFPREDICT, EKFUPDATE, TRACKASSIGN.
    if nargin < 8, u = 0; end
    if nargin < 9, B = zeros(size(x, 1), 1); end
    x = A * x + B * u;
    P = A * P * A.' + Q;
    y = z(:) - H * x;
    S = H * P * H.' + R;
    K = (P * H.') / S;
    x = x + K * y;
    P = (eye(numel(x)) - K * H) * P;
end
