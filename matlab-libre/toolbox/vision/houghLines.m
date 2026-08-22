function [droites, accumulateur, theta, rho] = houghLines(bw, nombre)
%HOUGHLINES Détection de droites par transformée de Hough.
%   [D,A] = HOUGHLINES(BW,N) rend les N droites les plus votées, sous
%   forme de couples [rho theta] (theta en degrés).
    if nargin < 2
        nombre = 5;
    end
    [h, l] = size(bw);
    theta = -90:89;
    rhoMax = ceil(sqrt(h^2 + l^2));
    rho = -rhoMax:rhoMax;
    accumulateur = zeros(numel(rho), numel(theta));
    for i = 1:h
        for j = 1:l
            if ~bw(i, j)
                continue;
            end
            for t = 1:numel(theta)
                a = theta(t) * pi / 180;
                r = round(j * cos(a) + i * sin(a)) + rhoMax + 1;
                if r >= 1 && r <= numel(rho)
                    accumulateur(r, t) = accumulateur(r, t) + 1;
                end
            end
        end
    end
    droites = [];
    A = accumulateur;
    for k = 1:nombre
        [~, indice] = max(A(:));
        [r, t] = ind2sub(size(A), indice);
        if A(r, t) == 0
            break;
        end
        droites(end+1, :) = [rho(r), theta(t)];
        a = max(1, r-2):min(size(A,1), r+2);
        b = max(1, t-2):min(size(A,2), t+2);
        A(a, b) = 0;
    end
end
