function e = expectedShortfall(rendements, niveau)
%EXPECTEDSHORTFALL Perte moyenne conditionnelle au-delà de la VaR.
    if nargin < 2
        niveau = 0.95;
    end
    r = rendements(:);
    seuil = quantile(r, 1 - niveau);
    queue = r(r <= seuil);
    if isempty(queue)
        e = -seuil;
    else
        e = -mean(queue);
    end
end
