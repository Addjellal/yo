function fd = dopplerShift(vitesse, frequence, c)
%DOPPLERSHIFT Décalage Doppler d'une cible en rapprochement.
    if nargin < 3
        c = 299792458;
    end
    fd = 2 * vitesse .* frequence / c;
end
