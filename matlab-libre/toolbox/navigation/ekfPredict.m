function [x, P] = ekfPredict(x, P, f, F, Q)
%EKFPREDICT Étape de prédiction d'un filtre de Kalman étendu.
%   [X,P] = EKFPREDICT(X,P,F,JACOBIENNE,Q) où F est la fonction d'état.
    x = f(x);
    P = F * P * F.' + Q;
end
