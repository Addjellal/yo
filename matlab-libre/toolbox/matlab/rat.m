function [n, d] = rat(x, tol)
%RAT Approximation rationnelle par fractions continues.
%   [N,D] = RAT(X) rend deux entiers tels que N/D vaut X à la tolérance
%   par défaut près (1e-6 fois la valeur).
%   S = RAT(X) rend la chaîne « n/d ».
    if nargin < 2
        tol = 1e-6 * max(abs(x(:)));
        if tol == 0
            tol = 1e-6;
        end
    end
    n = zeros(size(x));
    d = ones(size(x));
    for k = 1:numel(x)
        v = x(k);
        p0 = 0; q0 = 1; p1 = 1; q1 = 0;
        reste = v;
        for iteration = 1:30
            a = floor(reste);
            p2 = a * p1 + p0;
            q2 = a * q1 + q0;
            p0 = p1; q0 = q1; p1 = p2; q1 = q2;
            if q1 ~= 0 && abs(p1 / q1 - v) <= tol
                break;
            end
            f = reste - a;
            if f == 0
                break;
            end
            reste = 1 / f;
        end
        n(k) = p1;
        d(k) = q1;
    end
    if nargout <= 1
        if numel(x) == 1
            n = sprintf('%d/%d', n, d);
        end
    end
end
