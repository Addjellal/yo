function vitesse = gearRatioSpeed(regime, rapport, rapportFinal, rayonRoue)
%GEARRATIOSPEED Vitesse du véhicule pour un régime moteur donné.
%   VITESSE = GEARRATIOSPEED(REGIME,RAPPORT,RAPPORTFINAL,RAYONROUE) rend
%   la vitesse du véhicule. REGIME est en tours par minute, VITESSE en
%   mètres par seconde.
%
%   La boîte ne fait qu'échanger couple contre vitesse : une fois le
%   rapport choisi, régime moteur et vitesse sont liés rigidement. La roue
%   tourne à REGIME/(RAPPORT x RAPPORTFINAL) tours par minute et avance de
%   2 pi R par tour — c'est tout le calcul.
%
%   La vitesse est donc proportionnelle au régime et inversement
%   proportionnelle à la démultiplication.
%
%   Exemple :
%      gearRatioSpeed(3000, 1.0, 3.9, 0.32) * 3.6   % en km/h, en 4e
%      gearRatioSpeed(6000, 1.0, 3.9, 0.32)         % le double
%
%   Voir aussi LONGITUDINAL, TIREFORCE.
    vitesse = (regime * 2 * pi / 60) / (rapport * rapportFinal) * rayonRoue;
end
