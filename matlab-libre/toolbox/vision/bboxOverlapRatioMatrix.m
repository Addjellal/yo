function r = bboxOverlapRatioMatrix(a, b)
%BBOXOVERLAPRATIOMATRIX Recouvrement de toutes les paires de boîtes.
%   R(i,j) est le rapport de l'intersection sur l'union entre A(i,:) et
%   B(j,:). C'est la forme matricielle de BBOXOVERLAPRATIO.
    na = size(a, 1);
    nb = size(b, 1);
    r = zeros(na, nb);
    for i = 1:na
        for j = 1:nb
            r(i, j) = bboxOverlapRatio(a(i, :), b(j, :));
        end
    end
end
