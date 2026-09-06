function L = pathLoss(distance, frequence, exposant)
%PATHLOSS Affaiblissement de parcours en décibels.
%   L = PATHLOSS(D,F) applique le modèle en espace libre ; l'exposant
%   permet de rendre compte d'un environnement plus difficile.
%
%   L = PATHLOSS(D,F,N) rend 10 N log10(4 pi D / lambda) décibels.
%
%   L'exposant vaut deux en espace libre : la puissance s'étale sur une
%   sphère, et chaque doublement de distance coûte six décibels. En ville
%   il monte à trois ou quatre — réflexions, diffractions, obstacles — et
%   chaque doublement coûte alors neuf ou douze décibels.
%
%   Monter en fréquence coûte aussi : à distance égale, doubler la
%   fréquence coûte six décibels, parce qu'une antenne de gain donné y
%   capte une surface plus petite.
%
%   Exemple :
%      pathLoss(1000, 2.4e9)           % environ 100 dB
%      pathLoss(2000, 2.4e9) - pathLoss(1000, 2.4e9)   % 6 dB
%      pathLoss(2000, 2.4e9, 4) - pathLoss(1000, 2.4e9, 4)   % 12 dB
%
%   Voir aussi FRIIS, THROUGHPUTSHANNON, W2DBM.
    if nargin < 3
        exposant = 2;
    end
    c = 299792458;
    lambda = c ./ frequence;
    L = 10 * exposant * log10(4 * pi * distance ./ lambda);
end
