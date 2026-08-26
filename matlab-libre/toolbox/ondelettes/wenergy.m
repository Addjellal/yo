function [energieApproximation, energiesDetails] = wenergy(C, L)
%WENERGY Répartition de l'énergie entre approximation et détails.
    total = sum(C .^ 2);
    a = C(1:L(1));
    energieApproximation = 100 * sum(a .^ 2) / total;
    energiesDetails = [];
    debut = L(1) + 1;
    for k = 2:numel(L)-1
        d = C(debut:debut + L(k) - 1);
        energiesDetails(end+1) = 100 * sum(d .^ 2) / total;
        debut = debut + L(k);
    end
end
