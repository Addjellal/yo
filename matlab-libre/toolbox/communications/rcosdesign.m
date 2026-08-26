function h = rcosdesign(beta, symboles, echantillons, forme)
%RCOSDESIGN Filtre en cosinus surélevé, ou sa racine.
%   H = RCOSDESIGN(BETA,SPAN,SPS,'sqrt') rend la racine du cosinus
%   surélevé, normalisée en énergie.
    if nargin < 4
        forme = 'sqrt';
    end
    n = symboles * echantillons;
    t = (-n/2:n/2) / echantillons;
    h = zeros(size(t));
    for k = 1:numel(t)
        x = t(k);
        if strcmpi(forme, 'normal')
            if x == 0
                h(k) = 1;
            elseif abs(abs(2 * beta * x) - 1) < 1e-9
                h(k) = pi / 4 * sinc(1 / (2 * beta));
            else
                h(k) = sinc(x) * cos(pi * beta * x) / (1 - (2 * beta * x) ^ 2);
            end
        else
            if x == 0
                h(k) = (1 + beta * (4 / pi - 1));
            elseif abs(abs(4 * beta * x) - 1) < 1e-9
                h(k) = beta / sqrt(2) * ((1 + 2/pi) * sin(pi / (4*beta)) + ...
                                          (1 - 2/pi) * cos(pi / (4*beta)));
            else
                num = sin(pi * x * (1 - beta)) + 4 * beta * x * cos(pi * x * (1 + beta));
                den = pi * x * (1 - (4 * beta * x) ^ 2);
                h(k) = num / den;
            end
        end
    end
    h = h / norm(h);
end
