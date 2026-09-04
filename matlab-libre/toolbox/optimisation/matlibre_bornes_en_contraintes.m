function [A, b] = matlibre_bornes_en_contraintes(A, b, bas, haut, n)
%MATLIBRE_BORNES_EN_CONTRAINTES Ajoute les bornes aux inégalités.
%   Une borne inférieure x >= bas s'écrit -x <= -bas ; une borne
%   supérieure s'écrit telle quelle. Les bornes infinies sont ignorées.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isempty(A)
        A = zeros(0, n);
        b = zeros(0, 1);
    else
        b = b(:);
    end
    if ~isempty(bas)
        bas = bas(:);
        if isscalar(bas), bas = repmat(bas, n, 1); end
        finies = isfinite(bas);
        indices = find(finies);
        for k = 1:numel(indices)
            ligne = zeros(1, n);
            ligne(indices(k)) = -1;
            A = [A; ligne];              %#ok<AGROW>
            b = [b; -bas(indices(k))];   %#ok<AGROW>
        end
    end
    if ~isempty(haut)
        haut = haut(:);
        if isscalar(haut), haut = repmat(haut, n, 1); end
        finies = isfinite(haut);
        indices = find(finies);
        for k = 1:numel(indices)
            ligne = zeros(1, n);
            ligne(indices(k)) = 1;
            A = [A; ligne];             %#ok<AGROW>
            b = [b; haut(indices(k))];  %#ok<AGROW>
        end
    end
end
