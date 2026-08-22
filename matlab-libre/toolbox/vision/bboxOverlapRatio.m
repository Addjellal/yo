function r = bboxOverlapRatio(a, b)
%BBOXOVERLAPRATIO Recouvrement de boîtes englobantes (intersection/union).
%   Les boîtes s'écrivent [x y largeur hauteur].
    r = zeros(size(a, 1), size(b, 1));
    for i = 1:size(a, 1)
        for j = 1:size(b, 1)
            x1 = max(a(i,1), b(j,1));
            y1 = max(a(i,2), b(j,2));
            x2 = min(a(i,1)+a(i,3), b(j,1)+b(j,3));
            y2 = min(a(i,2)+a(i,4), b(j,2)+b(j,4));
            inter = max(0, x2 - x1) * max(0, y2 - y1);
            union = a(i,3)*a(i,4) + b(j,3)*b(j,4) - inter;
            if union > 0
                r(i, j) = inter / union;
            end
        end
    end
end
