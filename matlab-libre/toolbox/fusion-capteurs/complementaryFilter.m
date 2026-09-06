function angle = complementaryFilter(angleAccel, vitesseGyro, dt, alpha, anglePrecedent)
%COMPLEMENTARYFILTER Fusion d'un angle bruité et d'une vitesse dérivante.
%   ANGLE = COMPLEMENTARYFILTER(ANGLEACCEL,VITESSEGYRO,DT,ALPHA,PRECEDENT)
%   combine un angle mesuré — juste en moyenne mais bruité — et une
%   vitesse angulaire — propre mais dont l'intégrale dérive :
%
%      angle = ALPHA (precedent + vitesse DT) + (1 - ALPHA) angleAccel
%
%   ALPHA vaut 0,98 par défaut ; PRECEDENT vaut l'angle mesuré au premier
%   appel, ce qui évite un transitoire au démarrage.
%
%   C'est un passe-haut sur le gyromètre et un passe-bas sur
%   l'accéléromètre, dont la somme fait exactement un — d'où « filtre
%   complémentaire ». La constante de temps de la coupure vaut
%   ALPHA DT / (1 - ALPHA) : c'est la durée pendant laquelle on fait
%   confiance au gyromètre avant que l'accéléromètre reprenne la main.
%
%   Le réglage d'ALPHA arbitre entre bruit et retard, une fois pour
%   toutes. KALMANFILTER refait cet arbitrage à chaque pas à partir des
%   covariances, et sait en prime estimer le biais du gyromètre — au prix
%   d'un modèle qu'il faut écrire.
%
%   Exemple :
%      angle = 0;
%      for k = 1:100
%          angle = complementaryFilter(mesure(k), gyro(k), 0.01, 0.98, angle);
%      end
%
%   Voir aussi KALMANFILTER, MADGWICKUPDATE.
    if nargin < 4, alpha = 0.98; end
    if nargin < 5, anglePrecedent = angleAccel; end
    angle = alpha * (anglePrecedent + vitesseGyro * dt) + (1 - alpha) * angleAccel;
end
