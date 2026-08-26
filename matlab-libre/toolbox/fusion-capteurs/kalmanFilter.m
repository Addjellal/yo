function [x, P] = kalmanFilter(x, P, z, A, H, Q, R, u, B)
%KALMANFILTER Un pas de filtre de Kalman linéaire (prédiction et correction).
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
