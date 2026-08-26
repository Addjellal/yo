function angle = complementaryFilter(angleAccel, vitesseGyro, dt, alpha, anglePrecedent)
%COMPLEMENTARYFILTER Fusion d'un angle bruité et d'une vitesse dérivante.
    if nargin < 4, alpha = 0.98; end
    if nargin < 5, anglePrecedent = angleAccel; end
    angle = alpha * (anglePrecedent + vitesseGyro * dt) + (1 - alpha) * angleAccel;
end
