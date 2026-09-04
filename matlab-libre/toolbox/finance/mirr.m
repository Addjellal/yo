function taux = mirr(flux, tauxFinancement, tauxReplacement)
%MIRR Taux de rendement interne modifié.
%   R = MIRR(FLUX,TF,TR) suppose que les décaissements sont financés au
%   taux TF et que les encaissements sont replacés au taux TR, jusqu'à la
%   fin de la période.
%
%   Le taux de rendement interne ordinaire suppose que chaque
%   encaissement est replacé au taux qu'il cherche lui-même, ce qui n'a
%   pas de sens quand ce taux est très élevé. Il peut aussi être multiple
%   si les flux changent de signe plusieurs fois. Le taux modifié écarte
%   les deux difficultés en fixant explicitement les taux de financement
%   et de replacement.
%
%   Exemple :
%      mirr([-100 30 40 50 20], 0.10, 0.06)
%
%   Voir aussi IRR, PVVAR, FVVAR, NPV.
    flux = double(flux(:));
    n = numel(flux) - 1;
    negatifs = flux;
    negatifs(negatifs > 0) = 0;
    positifs = flux;
    positifs(positifs < 0) = 0;
    valeurNegative = pvvar(negatifs, tauxFinancement);
    valeurPositive = fvvar(positifs, tauxReplacement);
    if valeurNegative == 0
        error('finance:mirr:AucunDecaissement', ...
              'La série ne contient aucun flux négatif.');
    end
    taux = (-valeurPositive / valeurNegative) ^ (1 / n) - 1;
end
