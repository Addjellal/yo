function couleurs = label2rgb(etiquettes, carte, fond)
%LABEL2RGB Colorie une image étiquetée.
%   RGB = LABEL2RGB(L) donne une couleur par étiquette ; le fond (zéro)
%   reste blanc. LABEL2RGB(L,CARTE,FOND) choisit la palette et la couleur
%   du fond.
    if nargin < 3 || isempty(fond), fond = [1 1 1]; end
    n = max(1, max(etiquettes(:)));
    if nargin < 2 || isempty(carte) || ischar(carte)
        % Palette régulière en teinte : des couleurs bien séparées.
        teintes = (0:n-1)' / n;
        carte = hsv2rgb(reshape([teintes, ones(n, 1), ones(n, 1)], n, 1, 3));
        carte = reshape(carte, n, 3);
    end
    [m, k] = size(etiquettes);
    couleurs = zeros(m, k, 3);
    for plan = 1:3
        c = fond(plan) * ones(m, k);
        for e = 1:n
            c(etiquettes == e) = carte(min(e, size(carte, 1)), plan);
        end
        couleurs(:, :, plan) = c;
    end
end
