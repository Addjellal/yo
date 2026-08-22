function lisse = smoothPath(chemin, poidsDonnees, poidsLissage, tolerance)
%SMOOTHPATH Lissage d'une trajectoire par descente de gradient.
    if nargin < 2, poidsDonnees = 0.5; end
    if nargin < 3, poidsLissage = 0.3; end
    if nargin < 4, tolerance = 1e-6; end
    lisse = chemin;
    changement = tolerance + 1;
    while changement >= tolerance
        changement = 0;
        for i = 2:size(chemin, 1) - 1
            for j = 1:size(chemin, 2)
                ancien = lisse(i, j);
                lisse(i, j) = lisse(i, j) + poidsDonnees * (chemin(i, j) - lisse(i, j)) ...
                    + poidsLissage * (lisse(i-1, j) + lisse(i+1, j) - 2 * lisse(i, j));
                changement = changement + abs(ancien - lisse(i, j));
            end
        end
    end
end
