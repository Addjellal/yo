function matlibre_courbes_dessous(entrees)
%MATLIBRE_COURBES_DESSOUS Lignes de niveau dans le plan du bas.
%   Fonction interne : elle n'existe pas dans MATLAB. MESHC et SURFC
%   tracent la surface, puis appellent MATLIBRE_COURBES_DESSOUS avec les
%   mêmes données pour poser ses lignes de niveau dans le plan du bas de
%   l'axe (sa borne inférieure en z), chacune de la couleur de son niveau.
%
%   Exemple :
%      mesh(peaks(20)); hold on; matlibre_courbes_dessous({peaks(20)}); hold off;
%
%   Voir aussi MESHC, SURFC, CONTOURC.
    numeriques = entrees(cellfun(@isnumeric, entrees));
    if numel(numeriques) >= 3
        X = numeriques{1};
        Y = numeriques{2};
        Z = numeriques{3};
        if ~isvector(X)
            X = X(1, :);
        end
        if ~isvector(Y)
            Y = Y(:, 1);
        end
    else
        Z = numeriques{1};
        X = 1:size(Z, 2);
        Y = 1:size(Z, 1);
    end
    bornes = zlim();
    palette = colormap();
    lim = clim();
    C = contourc(X(:)', Y(:)', Z, 10);
    k = 1;
    while k < size(C, 2)
        niveau = C(1, k);
        nombre = C(2, k);
        xs = C(1, k + 1:k + nombre);
        ys = C(2, k + 1:k + nombre);
        rang = floor((niveau - lim(1)) / (lim(2) - lim(1)) * size(palette, 1)) + 1;
        rang = min(max(rang, 1), size(palette, 1));
        plot3(xs, ys, bornes(1) * ones(size(xs)), 'Color', palette(rang, :));
        k = k + nombre + 1;
    end
    zlim(bornes);
end
