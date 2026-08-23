function [indices, carte] = rgb2ind(rgb, n)
%RGB2IND Image en couleurs vers image indexée.
%   [X,MAP] = RGB2IND(RGB,N) réduit l'image à N couleurs par les
%   k-moyennes sur les pixels, initialisées régulièrement pour que le
%   résultat ne dépende pas du tirage.
%
%   [X,MAP] = RGB2IND(RGB,MAP) utilise la palette donnée et affecte
%   chaque pixel à sa couleur la plus proche.
%
%   Exemple :
%      [x, map] = rgb2ind(cat(3, [0 1], [0 1], [0 1]), 2);
    rgb = im2double(rgb);
    d = size(rgb);
    pixels = reshape(rgb, [], 3);
    if numel(n) > 1
        carte = double(n);
    else
        carte = paletteParGroupes(pixels, n);
    end
    indices = plusProche(pixels, carte) - 1;
    indices = reshape(indices, d(1:2));
end

function carte = paletteParGroupes(pixels, n)
%PALETTEPARGROUPES k-moyennes déterministes sur les couleurs.
    uniques = unique(round(pixels * 255) / 255, 'rows');
    if size(uniques, 1) <= n
        carte = uniques;
        if size(carte, 1) < n
            carte(end+1:n, :) = repmat(carte(end, :), n - size(carte, 1), 1);
        end
        return
    end
    % Amorçage régulier : on prend n couleurs réparties dans la liste
    % triée, ce qui rend le résultat reproductible.
    pas = max(1, floor(size(uniques, 1) / n));
    carte = uniques(1:pas:pas * n, :);
    carte = carte(1:n, :);
    for tour = 1:30
        affectation = plusProche(pixels, carte);
        nouvelle = carte;
        for k = 1:n
            dedans = affectation == k;
            if any(dedans)
                nouvelle(k, :) = mean(pixels(dedans, :), 1);
            end
        end
        if max(max(abs(nouvelle - carte))) < 1e-9
            carte = nouvelle;
            break
        end
        carte = nouvelle;
    end
end

function indices = plusProche(pixels, carte)
    n = size(carte, 1);
    distances = zeros(size(pixels, 1), n);
    for k = 1:n
        ecart = pixels - repmat(carte(k, :), size(pixels, 1), 1);
        distances(:, k) = sum(ecart .^ 2, 2);
    end
    [~, indices] = min(distances, [], 2);
end
