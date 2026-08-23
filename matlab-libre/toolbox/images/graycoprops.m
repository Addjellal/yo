function s = graycoprops(glcm, proprietes)
%GRAYCOPROPS Descripteurs d'une matrice de cooccurrence.
%   S = GRAYCOPROPS(GLCM) rend Contrast, Correlation, Energy et
%   Homogeneity, telles que les définit la documentation MathWorks.
    if nargin < 2 || isempty(proprietes)
        proprietes = {'Contrast', 'Correlation', 'Energy', 'Homogeneity'};
    elseif ischar(proprietes) || isstring(proprietes)
        if strcmpi(char(proprietes), 'all')
            proprietes = {'Contrast', 'Correlation', 'Energy', 'Homogeneity'};
        else
            proprietes = {char(proprietes)};
        end
    end
    nombre = size(glcm, 3);
    s = struct();
    for k = 1:numel(proprietes)
        s.(char(proprietes{k})) = zeros(1, nombre);
    end
    for d = 1:nombre
        p = glcm(:, :, d);
        total = sum(p(:));
        if total > 0, p = p / total; end
        n = size(p, 1);
        [j, i] = meshgrid(1:n, 1:n);
        mi = sum(sum(i .* p));
        mj = sum(sum(j .* p));
        si = sqrt(sum(sum((i - mi).^2 .* p)));
        sj = sqrt(sum(sum((j - mj).^2 .* p)));
        for k = 1:numel(proprietes)
            nom = char(proprietes{k});
            switch lower(nom)
                case 'contrast'
                    s.Contrast(d) = sum(sum((i - j).^2 .* p));
                case 'correlation'
                    if si > 0 && sj > 0
                        s.Correlation(d) = sum(sum((i - mi) .* (j - mj) .* p)) / (si * sj);
                    else
                        s.Correlation(d) = NaN;
                    end
                case 'energy'
                    s.Energy(d) = sum(sum(p.^2));
                case 'homogeneity'
                    s.Homogeneity(d) = sum(sum(p ./ (1 + abs(i - j))));
            end
        end
    end
end
