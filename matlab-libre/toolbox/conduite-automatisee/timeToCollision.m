function t = timeToCollision(distance, vitesseRelative)
%TIMETOCOLLISION Temps avant collision, en secondes.
%   Rend l'infini si la vitesse relative n'est pas un rapprochement.
%
%   T = TIMETOCOLLISION(DISTANCE,VITESSERELATIVE) rend distance divisée
%   par vitesse, en secondes. La fonction est vectorisée : tous les objets
%   détectés se traitent d'un coup.
%
%   La distance seule ne dit rien : trente mètres à vitesse égale sont
%   sûrs, trente mètres à vingt mètres par seconde de rapprochement
%   laissent une seconde et demie. C'est le temps, non la distance, qui
%   décide — et le plus urgent n'est donc pas le plus proche.
%
%   Un seuil de freinage d'urgence se pose directement sur ce temps, ce
%   qui le rend indépendant de la vitesse du véhicule.
%
%   Exemple :
%      timeToCollision(30, 20)         % 1.5 s
%      timeToCollision(30, 0)          % Inf : meme vitesse
%      [t, k] = min(timeToCollision([50 30 6 12], [10 -2 3 20]))
%
%   Voir aussi LANEOFFSET, PUREPURSUIT.
    t = inf(size(distance));
    approche = vitesseRelative > 0;
    t(approche) = distance(approche) ./ vitesseRelative(approche);
end
