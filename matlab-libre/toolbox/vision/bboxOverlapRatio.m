function r = bboxOverlapRatio(a, b, ratioType)
%BBOXOVERLAPRATIO Recouvrement de boîtes englobantes.
%   R = BBOXOVERLAPRATIO(A,B) rend, pour chaque boîte de A (M x 4) et
%   chaque boîte de B (N x 4), le rapport de l'aire de leur intersection à
%   celle de leur union : l'indice de Jaccard, ou IoU. Les boîtes
%   s'écrivent [x y largeur hauteur] ; R est M x N.
%   R = BBOXOVERLAPRATIO(A,B,RATIOTYPE) choisit le dénominateur : 'Union'
%   (défaut) ou 'Min', la plus petite des deux aires.
%
%   Exemple :
%      % Documentation de MATLAB.
%      bboxA = [150 80 100 100];
%      bboxOverlapRatio(bboxA, bboxA + 50)             % 0.0833
%      bboxOverlapRatio(bboxA, bboxA + 50, 'Min')      % 0.25
%
%   Voir aussi BBOXOVERLAPRATIOMATRIX, SELECTSTRONGESTBBOX, BBOX2POINTS.
    if nargin < 3
        ratioType = 'Union';
    end
    parUnion = strcmpi(ratioType, 'Union');
    if ~parUnion && ~strcmpi(ratioType, 'Min')
        error('vision:bboxOverlapRatio:Type', 'RATIOTYPE vaut ''Union'' ou ''Min''.');
    end
    if size(a, 2) ~= 4 || size(b, 2) ~= 4
        error('vision:bboxOverlapRatio:Taille', 'Les boîtes sont des lignes [x y largeur hauteur].');
    end
    a = double(a);
    b = double(b);
    largeur = max(0, min(a(:, 1) + a(:, 3), (b(:, 1) + b(:, 3)).') - max(a(:, 1), b(:, 1).'));
    hauteur = max(0, min(a(:, 2) + a(:, 4), (b(:, 2) + b(:, 4)).') - max(a(:, 2), b(:, 2).'));
    inter = largeur .* hauteur;
    aireA = a(:, 3) .* a(:, 4);
    aireB = (b(:, 3) .* b(:, 4)).';
    if parUnion
        denominateur = aireA + aireB - inter;
    else
        denominateur = min(aireA, aireB);
    end
    r = zeros(size(inter));
    positif = denominateur > 0;
    r(positif) = inter(positif) ./ denominateur(positif);
end
