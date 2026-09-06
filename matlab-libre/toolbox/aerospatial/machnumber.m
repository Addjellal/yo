function M = machnumber(vitesse, vitesseSon)
%MACHNUMBER Nombre de Mach.
%   M = MACHNUMBER(VITESSE,VITESSESON) rend le rapport des deux.
%
%   Le nombre de Mach, non la vitesse, est ce qui gouverne l'aérodynamique
%   au-delà d'environ 0,3 : c'est lui qui décide de la compressibilité de
%   l'air, de l'apparition des ondes de choc et de la traînée d'onde.
%
%   La vitesse du son décroissant avec l'altitude, une vitesse constante
%   donne un Mach croissant : un avion qui monte à vitesse indiquée
%   constante s'approche du transsonique sans accélérer.
%
%   Exemple :
%      [~, a] = atmosisa(11000);
%      machnumber(250, a)                  % environ 0,85
%      machnumber(250, 340)                % le meme avion au sol
%
%   Voir aussi ATMOSISA, DPRESSURE.
    M = vitesse ./ vitesseSon;
end
