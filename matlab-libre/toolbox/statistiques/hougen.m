function y = hougen(beta, x)
%HOUGEN Modèle de vitesse de réaction de Hougen-Watson.
%   Y = HOUGEN(BETA,X) évalue
%
%              b1 * x2 - x3 / b5
%      y = ---------------------------
%          1 + b2*x1 + b3*x2 + b4*x3
%
%   où X porte trois colonnes — les pressions partielles d'hydrogène, de
%   n-pentane et d'isopentane — et BETA cinq paramètres.
%
%   C'est le modèle de cinétique chimique dont MATLAB se sert depuis
%   toujours pour illustrer l'ajustement non linéaire : il est réputé
%   difficile, ses paramètres étant fortement corrélés et le point de
%   départ décidant du minimum atteint.
%
%   Exemples :
%      % Les donnees de Hougen et Watson, telles que Bates et Watts
%      % les publient
%      x = [470 300 10; 285 80 10; 470 300 120; 470 80 120; 470 80 10;
%           100 190 10; 100 80 65; 470 190 65; 100 300 54; 100 300 120;
%           100 80 120; 285 300 10; 285 190 120];
%      y = [8.55; 3.79; 4.82; 0.02; 2.75; 14.39; 2.54; 4.35; 13.00;
%           8.50; 0.05; 11.32; 3.13];
%      beta = nlinfit(x, y, @hougen, [1 0.05 0.02 0.1 2]);
%      max(abs(y - hougen(beta, x)))
%
%   Voir aussi NLINFIT, NLPARCI, LSQCURVEFIT, FITNLM.
    b1 = beta(1);
    b2 = beta(2);
    b3 = beta(3);
    b4 = beta(4);
    b5 = beta(5);
    x1 = x(:, 1);
    x2 = x(:, 2);
    x3 = x(:, 3);
    y = (b1 * x2 - x3 / b5) ./ (1 + b2 * x1 + b3 * x2 + b4 * x3);
end
