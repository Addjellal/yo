function H = plotmatrix(X, Y, style)
%PLOTMATRIX Tableau de nuages de points, toutes les paires de colonnes.
%   PLOTMATRIX(X) trace, pour chaque paire de colonnes de X, le nuage de
%   l'une contre l'autre, dans une grille d'axes. La diagonale porte
%   l'histogramme de chaque colonne. C'est la façon la plus rapide de
%   voir d'un coup toutes les relations deux à deux d'un jeu de données.
%
%   PLOTMATRIX(X,Y) trace chaque colonne de Y contre chaque colonne de X.
%   La grille compte alors autant de lignes que Y a de colonnes et autant
%   de colonnes que X en a, et il n'y a pas d'histogramme.
%
%   PLOTMATRIX(...,STYLE) prend une chaîne de style, comme PLOT. Le
%   défaut est le point.
%
%   H = PLOTMATRIX(...) rend les poignées des nuages.
%
%   Exemples :
%      X = randn(200, 3);
%      X(:, 3) = X(:, 1) + 0.3 * randn(200, 1);
%      plotmatrix(X);                % la liaison 1-3 saute aux yeux
%
%      plotmatrix(randn(100, 2), randn(100, 3));
%
%   Voir aussi PLOT, SCATTER, SUBPLOT, CORR, PCA.
    avecY = nargin >= 2 && ~isempty(Y) && ~(ischar(Y) || isstring(Y));
    if nargin >= 2 && (ischar(Y) || isstring(Y))
        style = Y;
        avecY = false;
    end
    if nargin < 3 || isempty(style)
        style = '.';
    end
    if ~avecY
        Y = X;
    end
    p = size(X, 2);
    q = size(Y, 2);
    clf;
    H = [];
    for i = 1:q
        for j = 1:p
            subplot(q, p, (i - 1) * p + j);
            if ~avecY && i == j
                histogram(X(:, j));
            else
                H(end + 1) = plot(X(:, j), Y(:, i), style);   %#ok<AGROW>
            end
        end
    end
    if nargout == 0
        clear H;
    end
end
