function [F, FdB] = friisNoise(facteurs, gains)
%FRIISNOISE Facteur de bruit d'une chaîne d'étages (formule de Friis).
%   [F,FDB] = FRIISNOISE(FACTEURS,GAINS) rend le facteur de bruit total,
%   en linéaire et en décibels :
%
%      F = F1 + (F2-1)/G1 + (F3-1)/(G1 G2) + ...
%
%   FACTEURS compte un facteur de bruit par étage, GAINS un gain de moins
%   — celui du dernier étage ne sert à rien. Les deux sont linéaires, non
%   en décibels.
%
%   Ce que dit la formule : le premier étage domine, parce que le bruit
%   des suivants est divisé par tout le gain qui les précède. C'est
%   pourquoi l'amplificateur faible bruit se met tout devant, et pourquoi
%   ce qui vient après compte de moins en moins.
%
%   Le même matériel rangé à l'envers coûte des décibels de bruit en
%   plus : l'ordre est un choix de conception, non de commodité.
%
%   Exemple :
%      facteurs = 10 .^ ([1 3 10] / 10);      % 1, 3 et 10 dB
%      gains    = 10 .^ ([20 15] / 10);       % 20 et 15 dB
%      [~, FdB] = friisNoise(facteurs, gains) % a peine plus que 1 dB
%
%   Voir aussi DBM2W, W2DBM.
    F = facteurs(1);
    gainCumule = 1;
    for k = 2:numel(facteurs)
        gainCumule = gainCumule * gains(k - 1);
        F = F + (facteurs(k) - 1) / gainCumule;
    end
    FdB = 10 * log10(F);
end
