function [F, FdB] = friisNoise(facteurs, gains)
%FRIISNOISE Facteur de bruit d'une chaîne d'étages (formule de Friis).
%   F = FRIISNOISE(FACTEURS,GAINS) où les deux vecteurs sont linéaires.
    F = facteurs(1);
    gainCumule = 1;
    for k = 2:numel(facteurs)
        gainCumule = gainCumule * gains(k - 1);
        F = F + (facteurs(k) - 1) / gainCumule;
    end
    FdB = 10 * log10(F);
end
