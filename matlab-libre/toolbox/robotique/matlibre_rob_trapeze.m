function [position, vitesse, acceleration] = matlibre_rob_trapeze(t, distance, T, ta)
%MATLIBRE_ROB_TRAPEZE Profil trapézoïdal évalué aux instants T.
%   La vitesse monte linéairement pendant TA, tient le palier, puis
%   redescend pendant TA. Son aire vaut la distance, par construction :
%   c'est ce qui fixe la vitesse de palier.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    v = distance / (T - ta);
    a = v / ta;
    position = zeros(size(t));
    vitesse = zeros(size(t));
    acceleration = zeros(size(t));
    montee = t < ta;
    palier = t >= ta & t <= T - ta;
    descente = t > T - ta;
    position(montee) = 0.5 * a * t(montee) .^ 2;
    vitesse(montee) = a * t(montee);
    acceleration(montee) = a;
    position(palier) = 0.5 * a * ta ^ 2 + v * (t(palier) - ta);
    vitesse(palier) = v;
    reste = T - t(descente);
    position(descente) = distance - 0.5 * a * reste .^ 2;
    vitesse(descente) = a * reste;
    acceleration(descente) = -a;
end
