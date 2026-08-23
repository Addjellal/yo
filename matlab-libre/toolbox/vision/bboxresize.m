function b = bboxresize(bbox, echelle)
%BBOXRESIZE Redimensionne des boîtes englobantes.
%   B = BBOXRESIZE(BBOX,ECHELLE) où ECHELLE est un facteur ou un couple
%   [vertical horizontal], comme dans MATLAB.
%
%   Exemple :
%      bboxresize([1 1 10 20], 2)   % [2 2 20 40]
    if isscalar(echelle), echelle = [echelle echelle]; end
    b = bbox;
    b(:, 1) = bbox(:, 1) * echelle(2);
    b(:, 2) = bbox(:, 2) * echelle(1);
    b(:, 3) = bbox(:, 3) * echelle(2);
    b(:, 4) = bbox(:, 4) * echelle(1);
end
