function etat = bicycleModel(etat, vitesse, braquage, empattement, dt)
%BICYCLEMODEL Un pas du modèle bicyclette cinématique.
%   ETAT vaut [x y theta].
    x = etat(1); y = etat(2); theta = etat(3);
    x = x + vitesse * cos(theta) * dt;
    y = y + vitesse * sin(theta) * dt;
    theta = theta + vitesse / empattement * tan(braquage) * dt;
    etat = [x y theta];
end
