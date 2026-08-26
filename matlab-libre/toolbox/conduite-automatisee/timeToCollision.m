function t = timeToCollision(distance, vitesseRelative)
%TIMETOCOLLISION Temps avant collision, en secondes.
%   Rend l'infini si la vitesse relative n'est pas un rapprochement.
    t = inf(size(distance));
    approche = vitesseRelative > 0;
    t(approche) = distance(approche) ./ vitesseRelative(approche);
end
