function [precision, rappel] = bboxPrecisionRecall(detections, verite, seuil)
%BBOXPRECISIONRECALL Précision et rappel d'une détection de boîtes.
%   [P,R] = BBOXPRECISIONRECALL(D,V) compare les boîtes détectées aux
%   boîtes de vérité terrain. Une détection compte comme juste si son
%   recouvrement avec une boîte de vérité dépasse le seuil, et si cette
%   boîte n'a pas déjà été prise : une même vérité ne peut pas justifier
%   deux détections.
%
%   [P,R] = BBOXPRECISIONRECALL(D,V,SEUIL) fixe le seuil de recouvrement,
%   0.5 par défaut, valeur retenue par les concours de détection.
%
%   La précision est la part des détections qui sont justes, le rappel la
%   part des vérités qui ont été trouvées. Les deux se lisent ensemble :
%   détecter tout donne un rappel parfait et une précision nulle.
%
%   Exemple :
%      [p, r] = bboxPrecisionRecall([10 10 20 20], [10 10 20 20]);
%      % p = 1, r = 1
%
%   Voir aussi BBOXOVERLAPRATIO, SELECTSTRONGESTBBOX.
    if nargin < 3 || isempty(seuil), seuil = 0.5; end
    D = double(detections);
    V = double(verite);
    nDetections = size(D, 1);
    nVerites = size(V, 1);
    if nVerites == 0
        rappel = 1;
        if nDetections == 0
            precision = 1;
        else
            precision = 0;
        end
        return
    end
    if nDetections == 0
        precision = 1;
        rappel = 0;
        return
    end
    recouvrements = bboxOverlapRatioMatrix(D, V);
    prises = false(1, nVerites);
    justes = 0;
    for k = 1:nDetections
        [meilleur, indice] = max(recouvrements(k, :) .* double(~prises));
        if meilleur >= seuil && ~prises(indice)
            prises(indice) = true;
            justes = justes + 1;
        end
    end
    precision = justes / nDetections;
    rappel = justes / nVerites;
end
