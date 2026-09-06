function assignation = trackAssign(pistes, mesures, seuil)
%TRACKASSIGN Association mesures / pistes par plus proche voisin global.
%   A = TRACKASSIGN(PISTES,MESURES,SEUIL) rend, pour chaque piste, l'indice
%   de la mesure qui lui est attribuée, ou zéro si aucune ne convient.
%   PISTES et MESURES ont une ligne par objet et une colonne par
%   coordonnée. SEUIL est la distance au-delà de laquelle on préfère ne
%   rien attribuer ; il vaut l'infini par défaut.
%
%   Suivre plusieurs objets demande d'abord de savoir quelle mesure va à
%   quelle piste. Sans cette étape, deux objets qui se croisent échangent
%   leurs identités et les deux trajectoires deviennent fausses.
%
%   Une mesure attribuée ne l'est qu'une fois : les pistes se servent dans
%   l'ordre, chacune prenant la plus proche encore libre. Ce n'est pas
%   l'optimum global de l'affectation — l'algorithme hongrois le
%   donnerait — mais il ne peut pas attribuer la même mesure deux fois,
%   ce qui est l'erreur qui coûte le plus cher.
%
%   Le seuil est ce qui distingue le suivi de l'invention : sans lui, une
%   piste dont l'objet a disparu s'accroche à n'importe quoi.
%
%   Exemple :
%      pistes  = [0 0; 10 0];
%      mesures = [10.2 0.3; 0.1 -0.2];
%      trackAssign(pistes, mesures)          % [2 1]
%      trackAssign(pistes, [0.1 -0.2; 50 50], 3)   % [1 0]
%
%   Voir aussi KALMANFILTER, PDIST2.
    if nargin < 3
        seuil = inf;
    end
    assignation = zeros(size(pistes, 1), 1);
    disponibles = true(size(mesures, 1), 1);
    for k = 1:size(pistes, 1)
        meilleure = 0;
        meilleureDistance = seuil;
        for m = 1:size(mesures, 1)
            if ~disponibles(m)
                continue;
            end
            d = norm(pistes(k, :) - mesures(m, :));
            if d < meilleureDistance
                meilleureDistance = d;
                meilleure = m;
            end
        end
        if meilleure > 0
            assignation(k) = meilleure;
            disponibles(meilleure) = false;
        end
    end
end
