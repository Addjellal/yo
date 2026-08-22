function vitesse = gearRatioSpeed(regime, rapport, rapportFinal, rayonRoue)
%GEARRATIOSPEED Vitesse du véhicule pour un régime moteur donné.
%   REGIME en tours par minute, VITESSE en mètres par seconde.
    vitesse = (regime * 2 * pi / 60) / (rapport * rapportFinal) * rayonRoue;
end
