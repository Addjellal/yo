function [x, P] = ekfUpdate(x, P, z, h, H, R)
%EKFUPDATE Étape de correction d'un filtre de Kalman étendu.
    y = z(:) - h(x);
    S = H * P * H.' + R;
    K = (P * H.') / S;
    x = x + K * y;
    P = (eye(numel(x)) - K * H) * P;
end
