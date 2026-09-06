function [x, P] = ekfUpdate(x, P, z, h, H, R)
%EKFUPDATE Étape de correction d'un filtre de Kalman étendu.
%   [X,P] = EKFUPDATE(X,P,Z,H,JACOBIENNE,R) corrige l'estimation par la
%   mesure Z, H étant la fonction de mesure et R son bruit.
%
%   La correction diminue toujours l'incertitude : une mesure, si bruitée
%   soit-elle, apporte de l'information. Le régime permanent s'établit
%   quand cette diminution équilibre exactement l'augmentation de
%   EKFPREDICT.
%
%   Le filtre estime aussi ce qu'aucune mesure ne donne — une vitesse, un
%   biais — pourvu que le modèle les relie à ce qu'on mesure. Sur un
%   modèle position-vitesse où l'on ne mesure que la position, la vitesse
%   s'estime par la façon dont la position évolue, et non directement.
%   Son estimation instantanée vagabonde, mais sa moyenne converge.
%
%   Exemple :
%      H = [1 0];
%      [x, P] = ekfUpdate(x, P, mesure, @(v) H * v, H, 0.5);
%
%   Voir aussi EKFPREDICT, KALMANFILTER.
    y = z(:) - h(x);
    S = H * P * H.' + R;
    K = (P * H.') / S;
    x = x + K * y;
    P = (eye(numel(x)) - K * H) * P;
end
