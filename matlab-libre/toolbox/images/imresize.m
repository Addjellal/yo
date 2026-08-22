function y = imresize(x, facteur)
%IMRESIZE Redimensionnement par interpolation bilinéaire.
%   Y = IMRESIZE(X,F) multiplie les dimensions par F.
%   Y = IMRESIZE(X,[H L]) impose la taille de sortie.
    [h, l] = size(x);
    if numel(facteur) == 2
        nh = facteur(1);
        nl = facteur(2);
    else
        nh = max(1, round(h * facteur));
        nl = max(1, round(l * facteur));
    end
    y = zeros(nh, nl);
    for i = 1:nh
        for j = 1:nl
            % Correspondance entre centres de pixels, comme la fonction
            % de référence : le pixel i du résultat regarde le point
            % (i-0.5)*h/nh + 0.5 de la source.
            si = min(max((i - 0.5) * h / nh + 0.5, 1), h);
            sj = min(max((j - 0.5) * l / nl + 0.5, 1), l);
            i0 = floor(si); j0 = floor(sj);
            i1 = min(i0 + 1, h); j1 = min(j0 + 1, l);
            a = si - i0; b = sj - j0;
            y(i, j) = (1-a)*(1-b)*x(i0,j0) + a*(1-b)*x(i1,j0) + ...
                      (1-a)*b*x(i0,j1) + a*b*x(i1,j1);
        end
    end
end
