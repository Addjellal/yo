function etat = bicycleModel(etat, vitesse, braquage, empattement, dt)
%BICYCLEMODEL Un pas du modèle bicyclette cinématique.
%   ETAT = BICYCLEMODEL(ETAT,VITESSE,BRAQUAGE,EMPATTEMENT,DT) avance d'un
%   pas. ETAT vaut [X Y THETA], BRAQUAGE est en radians.
%
%   À braquage constant, le véhicule décrit un cercle de rayon
%   EMPATTEMENT / tan(BRAQUAGE) : c'est la formule d'Ackermann, et le
%   rayon ne dépend pas de la vitesse. C'est ce qui fait de ce modèle un
%   modèle *cinématique* : il ignore le glissement, la force centrifuge et
%   la limite d'adhérence, donc il ne vaut qu'à basse vitesse.
%
%   Braquer autant d'un côté puis de l'autre ramène le cap mais déplace
%   latéralement : c'est un changement de file, et c'est ainsi qu'on en
%   construit un.
%
%   Exemple :
%      etat = [0 0 0];
%      for k = 1:1000
%          etat = bicycleModel(etat, 5, deg2rad(10), 2.7, 0.01);
%      end
%
%   Voir aussi BICYCLEKINEMATICS, TIREFORCE, PUREPURSUIT.
    x = etat(1); y = etat(2); theta = etat(3);
    x = x + vitesse * cos(theta) * dt;
    y = y + vitesse * sin(theta) * dt;
    theta = theta + vitesse / empattement * tan(braquage) * dt;
    etat = [x y theta];
end
