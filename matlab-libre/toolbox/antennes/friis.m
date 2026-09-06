function Pr = friis(Pt, Gt, Gr, lambda, distance)
%FRIIS Puissance reçue en espace libre (formule de Friis).
%   PR = FRIIS(PT,GT,GR,LAMBDA,DISTANCE) rend la puissance reçue, en
%   watts. Les gains sont linéaires, non en décibels.
%
%   La puissance décroît comme le carré de la distance. Ce n'est pas une
%   perte dans le milieu — le vide n'absorbe rien — mais l'étalement de la
%   puissance sur une sphère de plus en plus grande : doubler la distance
%   coûte exactement six décibels.
%
%   La liaison est réciproque : échanger émetteur et récepteur ne change
%   rien. Et le gain se paie deux fois si les deux bouts en profitent.
%
%   La formule suppose l'espace libre, la polarisation adaptée et le champ
%   lointain. Rien de tout cela n'est vrai en intérieur, où l'exposant
%   effectif monte à trois ou quatre — c'est ce que PATHLOSS permet de
%   modéliser.
%
%   Exemple :
%      friis(1, 10, 10, 0.125, 100)
%      friis(1, 10, 10, 0.125, 200) / friis(1, 10, 10, 0.125, 100)  % 0.25
%
%   Voir aussi PATHLOSS, DIRECTIVITY, DBM2W.
    Pr = Pt .* Gt .* Gr .* (lambda ./ (4 * pi * distance)) .^ 2;
end
