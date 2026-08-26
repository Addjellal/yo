function Pr = friis(Pt, Gt, Gr, lambda, distance)
%FRIIS Puissance reçue en espace libre (formule de Friis).
    Pr = Pt .* Gt .* Gr .* (lambda ./ (4 * pi * distance)) .^ 2;
end
