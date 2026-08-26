function q = ikine2R(x, y, l1, l2, coudeHaut)
%IKINE2R Cinématique inverse d'un bras plan à deux segments.
%   Q = IKINE2R(X,Y,L1,L2) rend les deux angles articulaires.
    if nargin < 3, l1 = 1; end
    if nargin < 4, l2 = 1; end
    if nargin < 5, coudeHaut = true; end
    d = (x^2 + y^2 - l1^2 - l2^2) / (2 * l1 * l2);
    d = max(min(d, 1), -1);
    if coudeHaut
        q2 = acos(d);
    else
        q2 = -acos(d);
    end
    q1 = atan2(y, x) - atan2(l2 * sin(q2), l1 + l2 * cos(q2));
    q = [q1 q2];
end
