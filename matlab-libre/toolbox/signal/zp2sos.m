function [sos, g] = zp2sos(z, p, k)
%ZP2SOS Zéros et pôles vers sections du second ordre.
%   Les racines complexes sont appariées avec leur conjuguée ; les racines
%   réelles sont groupées deux par deux. Le résultat est réel.
    if nargin < 3, k = 1; end
    z = z(:);
    p = p(:);
    paires = @(r) apparier(r);
    zp = paires(z);
    pp = paires(p);
    n = max(size(zp, 1), size(pp, 1));
    sos = zeros(max(n, 1), 6);
    for i = 1:max(n, 1)
        if i <= size(zp, 1)
            num = real(poly(zp(i, ~isnan(zp(i, :)))));
        else
            num = 1;
        end
        if i <= size(pp, 1)
            den = real(poly(pp(i, ~isnan(pp(i, :)))));
        else
            den = 1;
        end
        num = [zeros(1, 3 - numel(num)), num];
        den = [zeros(1, 3 - numel(den)), den];
        % La section se lit [b0 b1 b2 a0 a1 a2] avec a0 = 1.
        sos(i, :) = [num(1:3) / 1, den(1:3)];
        if den(1) ~= 1 && den(1) ~= 0
            sos(i, 1:3) = sos(i, 1:3) / den(1);
            sos(i, 4:6) = sos(i, 4:6) / den(1);
        end
        if sos(i, 4) == 0
            sos(i, 4:6) = [1, sos(i, 5:6)];
        end
    end
    g = k;
end

function m = apparier(r)
%APPARIER Groupe les racines par deux, conjuguées ensemble.
    m = [];
    reste = r(:);
    while ~isempty(reste)
        courant = reste(1);
        reste(1) = [];
        if abs(imag(courant)) > 1e-12
            % On cherche le conjugué.
            [~, j] = min(abs(reste - conj(courant)));
            if ~isempty(j)
                m = [m; courant, reste(j)]; %#ok<AGROW>
                reste(j) = [];
            else
                m = [m; courant, NaN]; %#ok<AGROW>
            end
        elseif ~isempty(reste) && abs(imag(reste(1))) < 1e-12
            m = [m; courant, reste(1)]; %#ok<AGROW>
            reste(1) = [];
        else
            m = [m; courant, NaN]; %#ok<AGROW>
        end
    end
end
