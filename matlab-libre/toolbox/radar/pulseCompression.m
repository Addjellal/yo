function [y, retards] = pulseCompression(recu, impulsion)
%PULSECOMPRESSION Compression d'impulsion et position du maximum.
%   [Y,RETARDS] = PULSECOMPRESSION(RECU,IMPULSION) applique le filtre
%   adapté et rend, en plus, l'axe des retards en échantillons — décalé
%   pour que le maximum tombe sur le début de l'écho, non sur sa fin.
%
%   La compression d'impulsion résout un dilemme : une impulsion longue
%   porte de l'énergie, une impulsion brève sépare deux cibles proches.
%   Une impulsion longue modulée — un chirp — donne les deux à la fois,
%   parce que le filtre adapté la comprime à la durée qu'impose sa bande.
%
%   La résolution en distance ne dépend donc que de la bande occupée, non
%   de la durée de l'impulsion.
%
%   Exemple :
%      impulsion = exp(1i * pi * (0:63).^2 / 64);
%      recu = [zeros(1, 200), impulsion, zeros(1, 50)];
%      [y, retards] = pulseCompression(recu, impulsion);
%      [~, k] = max(abs(y));
%      retards(k)                      % 200 : la ou l'echo commence
%
%   Voir aussi MATCHEDFILTER, TIME2RANGE.
    y = matchedFilter(recu, impulsion);
    retards = (1:numel(y)) - numel(impulsion);
end
