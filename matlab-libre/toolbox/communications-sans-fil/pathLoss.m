function L = pathLoss(distance, frequence, exposant)
%PATHLOSS Affaiblissement de parcours en décibels.
%   L = PATHLOSS(D,F) applique le modèle en espace libre ; l'exposant
%   permet de rendre compte d'un environnement plus difficile.
    if nargin < 3
        exposant = 2;
    end
    c = 299792458;
    lambda = c ./ frequence;
    L = 10 * exposant * log10(4 * pi * distance ./ lambda);
end
