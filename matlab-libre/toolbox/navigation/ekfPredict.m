function [x, P] = ekfPredict(x, P, f, F, Q)
%EKFPREDICT Étape de prédiction d'un filtre de Kalman étendu.
%   [X,P] = EKFPREDICT(X,P,F,JACOBIENNE,Q) fait avancer l'estimation d'un
%   pas : l'état par la fonction F, sa covariance par la jacobienne.
%
%      X  l'état estimé          P  sa covariance
%      F  la fonction d'évolution, une poignée @(x)
%      JACOBIENNE  sa dérivée au point courant
%      Q  le bruit de modèle
%
%   La prédiction augmente toujours l'incertitude : P croît de Q. C'est
%   EKFUPDATE qui la fait décroître, en apportant une mesure.
%
%   L'étendu diffère du linéaire en ce qu'il propage l'état par la vraie
%   fonction et la covariance par sa linéarisation. C'est une
%   approximation : elle vaut tant que la fonction est presque affine à
%   l'échelle de l'incertitude, et se dégrade quand elle ne l'est plus.
%
%   Exemple :
%      F = [1 0.1; 0 1];
%      [x, P] = ekfPredict(x, P, @(v) F * v, F, diag([1e-3 1e-2]));
%
%   Voir aussi EKFUPDATE, KALMANFILTER.
    x = f(x);
    P = F * P * F.' + Q;
end
